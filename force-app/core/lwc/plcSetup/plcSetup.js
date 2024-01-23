/* eslint-disable consistent-return */
/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, track } from 'lwc';

import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import fetchAuthenticatedUsers from '@salesforce/apex/SetupController.fetchAuthenticatedUsers';
import fetchDeviceFlowAuthCodes from '@salesforce/apex/SetupController.fetchDeviceFlowAuthCodes';
import fetchOrgDomain from '@salesforce/apex/SetupController.fetchOrgDomain';
import revokeOAuthEnabledUserAccess from '@salesforce/apex/SetupController.revokeOAuthEnabledUserAccess';
import validatePendingDeviceFlowAuthentication from '@salesforce/apex/SetupController.validatePendingDeviceFlowAuthentication';

import { safeAwait } from 'c/plcUtils';

const AUTH_USER_COLUMNS = [
    { label: 'Domain', fieldName: 'domain', type: 'text' },
    { label: 'User', fieldName: 'usernameForDisplay', type: 'text' },
    { label: 'Username', fieldName: 'username', type: 'text' }
];

const MAX_VALIDATION_ATTEMPTS = 10;

const OAUTH_OPTIONS = [
    { label: 'Credentials', value: 'credentials' },
    { label: 'Device', value: 'device' },
    { label: 'JWT (Packaged Private Key)', value: 'jwtPackagedKey' },
    { label: 'JWT (Admin-Provided Private Key', value: 'jwtAdminProvidedKey' },
    { label: 'Web Server', value: 'web' }
];

const STEPS = [
    {
        index: 0,
        label: 'User Details',
        value: 'userDetailsStep'
    },
    {
        index: 1,
        label: 'Authentication',
        value: 'authStep'
    }
];

const SUCCESS_DELAY = 1500;

const VALIDATION_DELAY = 6000;

export default class PlcSetup extends LightningElement {

    authenticatedUsers = [];
    authVerified = false;
    columns = AUTH_USER_COLUMNS;
    currentStep = STEPS[0];
    deviceCode;
    isRevokeOAuthEnabledUserAccessDisabled = true;
    orgDomain;
    orgDomainExternalUrl;
    selectedOauthFlow = 'device';
    @track rows = [];
    userCode;

    get authUrlLabel() {
        return 'Visit authentication URL and enter code: ' + this.userCode;
    }

    get authUrlValue() {
        return (
            this.orgDomainExternalUrl +
            '/setup/connect?user_code=' +
            this.userCode
        );
    }

    get currentStepVal() {
        return this.currentStep.value;
    }

    get displayAuthUserTable() {
        return this.selectedOauthFlow !== 'credentials';
    }

    get displayDoneButton() {
        return this.authVerified;
    }

    get displayProceedButton() {
        return this.currentStep.value !== 'authStep';
    }

    get isAuthStep() {
        return this.currentStep.value === 'authStep';
    }

    get isAuthVerified() {
        return this.authVerified;
    }

    get isBackButtonDisabled() {
        return this.currentStep.index === 0;
    }

    get isUserDetailsStep() {
        return this.currentStep.value === 'userDetailsStep';
    }

    get oauthOptions() {
        return OAUTH_OPTIONS;
    }

    get steps() {
        return STEPS;
    }

    connectedCallback() {
        this.refreshAuthenticatedUsers();
        this.fetchOrgDomain();
    }

    async awaitAuthValidation(numAttempts) {
        numAttempts = numAttempts || 0;
        if (numAttempts >= MAX_VALIDATION_ATTEMPTS) {
            console.error('Something went wrong validating authentication - please try again!');
        }
        if (this.authVerified) {
            return;
        }
        const domain = this.orgDomain;
        const deviceCode = this.deviceCode;
        const [error, results] = await safeAwait(
            validatePendingDeviceFlowAuthentication({ domain, deviceCode })
        );
        if (error) {
            console.error(error.body.message);
        }
        if (results.is_authenticated) {
            return this.handleSuccessfulAuthentication();
        }
        window.setTimeout(() => {
            return this.awaitAuthValidation(numAttempts + 1);
        }, VALIDATION_DELAY);
    }

    async fetchDeviceFlowAuthCodes() {
        const domain = this.orgDomain;
        const [error, results] = await safeAwait(fetchDeviceFlowAuthCodes({ domain }));
        if (error) {
            console.error(error.body.message);
            return;
        }
        this.deviceCode = results.device_code;
        this.userCode = results.user_code;
        this.awaitAuthValidation();
    }

    async fetchOrgDomain() {
        const [error, results] = await safeAwait(fetchOrgDomain());
        if (error) {
            console.error(error.body.message);
            return;
        }
        this.orgDomainExternalUrl = results;
        const domainPrefix = 'https://';
        const domainStart = results.indexOf(domainPrefix) + domainPrefix.length;
        this.orgDomain = results.substring(
            domainStart,
            results.indexOf('.', domainStart)
        );
    }

    handleAddNewOauthEnabledUser() {
        const modal = this.template.querySelector('c-custom-modal');
        if (modal) {
            modal.openModal();
        }
    }

    handleDomainChange(event) {
        this.orgDomain = event.detail.value;
    }

    handleDone() {
        const modal = this.template.querySelector('c-custom-modal');
        if (modal) {
            modal.closeModal();
            this.refreshAuthenticatedUsers();
        }
    }

    handleModalClose() {
        this.authVerified = false;
        this.deviceCode = null;
        this.userCode = null;
        this.currentStep = STEPS[0];
    }

    handlePrevious() {
        this.currentStep = STEPS[this.currentStep.index - 1];
    }

    handleProceed() {
        if (this.currentStep.index === STEPS.length - 1) {
            // Save new oauth enabled user
        } else {
            if (this.currentStep.index === STEPS.length - 2) {
                this.fetchDeviceFlowAuthCodes();
            }
            this.currentStep = STEPS[this.currentStep.index + 1];
        }
    }

    async handleRevokeOauthEnabledUserAccess() {
        const selectedRows = this.template
            .querySelector('lightning-datatable')
            .getSelectedRows();
        if (selectedRows.length > 0) {
            const confirmRevoke = await LightningConfirm.open({
                message:
                    'Are you sure you want to revoke access for the selected OAuth Enabled User(s)?',
                theme: 'warning',
                label: 'Revoke Access'
            });
            if (confirmRevoke) {
                const usernamesToRevoke = selectedRows.map((item) => item.username);
                const [error] = await safeAwait(
                    revokeOAuthEnabledUserAccess({
                        usernamesToRevoke
                    })
                );
                if (error) {
                    console.error(error.body.message);
                    return;
                }
                this.authenticatedUsers = this.authenticatedUsers.filter(
                    (el) => !usernamesToRevoke.includes(el.username)
                );
                this.refreshTableRows();
                const showToastEvent = new ShowToastEvent({
                    message:
                        'Successfully revoked access for the selected OAuth Enabled User(s)',
                    title: 'OAuth Enabled User(s) Access Revoked',
                    variant: 'success'
                });
                this.dispatchEvent(showToastEvent);
            }
        }
    }

    handleRowSelectionChange() {
        const selectedRows = this.template
            .querySelector('lightning-datatable')
            .getSelectedRows();
        if (selectedRows.length === 0) {
            this.isRevokeOAuthEnabledUserAccessDisabled = true;
        } else {
            this.isRevokeOAuthEnabledUserAccessDisabled = false;
        }
    }

    handleSelectOauthFlow(event) {
        this.selectedOauthFlow = event.detail.value;
        this.refreshAuthenticatedUsers();
    }

    handleSuccessfulAuthentication() {
        // Delay displaying success message to allow time for CMDT to deploy to org
        window.setTimeout(() => {
            this.authVerified = true;
            const showToastEvent = new ShowToastEvent({
                message: 'Successfully created new OAuth enabled user!',
                title: 'Authentication Verified',
                variant: 'success'
            });
            this.dispatchEvent(showToastEvent);
        }, SUCCESS_DELAY);
    }

    async refreshAuthenticatedUsers() {
        const params = {
            oauthFlow: this.selectedOauthFlow
        };
        const [error, results] = await safeAwait(
            fetchAuthenticatedUsers(params)
        );
        if (error) {
            console.error(error.body.message);
        }
        this.authenticatedUsers = results;
        this.refreshTableRows();
    }

    refreshTableRows() {
        this.rows = this.authenticatedUsers.map((item) => {
            const domainPrefix = 'https://';
            const domainStart =
                item.domain.indexOf(domainPrefix) + domainPrefix.length;
            const domain = item.domain.substring(
                domainStart,
                item.domain.indexOf('.', domainStart)
            );
            return {
                domain,
                username: item.username,
                usernameForDisplay: item.usernameForDisplay
            };
        });
    }
}
