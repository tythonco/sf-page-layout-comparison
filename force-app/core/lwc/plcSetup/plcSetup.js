/* eslint-disable consistent-return */
/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, track } from 'lwc';

import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import fetchAuthorizedUsers from '@salesforce/apex/SetupController.fetchAuthorizedUsers';
import fetchConnectedAppInfo from '@salesforce/apex/SetupController.fetchConnectedAppInfo';
import fetchDeviceFlowAuthCodes from '@salesforce/apex/SetupController.fetchDeviceFlowAuthCodes';
import fetchOrgDomain from '@salesforce/apex/SetupController.fetchOrgDomain';
import fetchCurrentUsername from '@salesforce/apex/SetupController.fetchCurrentUsername';
import revokeOAuthEnabledUserAccess from '@salesforce/apex/SetupController.revokeOAuthEnabledUserAccess';
import testCredentialsFlowOrgDomainConnection from '@salesforce/apex/SetupController.testCredentialsFlowOrgDomainConnection';
import testJWTFlowOrgDomainConnection from '@salesforce/apex/SetupController.testJWTFlowOrgDomainConnection';
import validatePendingDeviceFlowAuthorization from '@salesforce/apex/SetupController.validatePendingDeviceFlowAuthorization';

import { safeAwait } from 'c/plcUtils';

import INSTALL_CA_FOR_CREDENTIALS_FLOW_GIF from '@salesforce/resourceUrl/installCAforCredentialsFlow';
import INSTALL_CA_FOR_JWT_KP_FLOW_GIF from '@salesforce/resourceUrl/installCAforJWTKPFlow';

const AUTH_USER_COLUMNS = [
    { label: 'Domain', fieldName: 'domain', type: 'text' },
    { label: 'User', fieldName: 'usernameForDisplay', type: 'text' },
    { label: 'Username', fieldName: 'username', type: 'text' }
];

const CMDT_UPSERT_METHOD_OPTIONS = [
    { label: '`Metadata` Apex Class (Asynchronous)', value: 'apex' },
    { label: 'Metadata API (Synchronous)', value: 'api' },
];

const MAX_VALIDATION_ATTEMPTS = 10;

const OAUTH_OPTIONS = [
    { label: 'Credentials', value: 'creds' },
    { label: 'Device', value: 'device' },
    { label: 'JWT (Packaged Private Key)', value: 'jwt_kp' },
    { label: 'JWT (Admin-Provided Private Key)', value: 'jwt_ak' },
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
        label: 'Authorization',
        value: 'authStep'
    }
];

const SUCCESS_DELAY = 1500;

const VALIDATION_DELAY = 6000;

export default class PlcSetup extends LightningElement {
    _isLoading = true;

    authorizedUsers = [];
    authVerified = false;
    caInfoByName;
    clientCredentialsAppId;
    clientCredentialsAppOrgId;
    columns = AUTH_USER_COLUMNS;
    currentStep = STEPS[0];
    deviceCode;
    installCAforCredentialsFlowGIFUrl = INSTALL_CA_FOR_CREDENTIALS_FLOW_GIF;
    installCAforJWTKeyPackagedFlowGIFUrl = INSTALL_CA_FOR_JWT_KP_FLOW_GIF;
    isRevokeOAuthEnabledUserAccessDisabled = true;
    jwtKPAppId;
    jwtKPAppOrgId;
    oauthFlowTestCertName;
    oauthFlowTestConsumerKey;
    oauthFlowTestOrgDomain;
    oauthFlowTestUsername;
    orgDomain;
    orgDomainExternalUrl;
    selectedCMDTUpsertMethod = 'apex';
    selectedOauthFlow = 'device';
    @track rows = [];
    userCode;

    get authUrlLabel() {
        return 'Visit authorization URL and enter code: ' + this.userCode;
    }

    get authUrlValue() {
        return (
            this.orgDomain +
            '.my.salesforce.com/setup/connect?user_code=' +
            this.userCode
        );
    }

    get caInstallUrlLabel() {
        return 'Install the connected app by clicking here';
    }

    get cmdtUpsertMethodOptions() {
        return CMDT_UPSERT_METHOD_OPTIONS;
    }

    get clientCredentialsAppInstallUrlValue() {
        return (
            this.oauthFlowTestOrgDomain +
            '.my.salesforce.com/identity/app/AppInstallApprovalPage.apexp?app_id=' +
            this.clientCredentialsAppId +
            '&app_org_id=' +
            this.clientCredentialsAppOrgId
        );
    }

    get jwtKeyPackagedInstallUrlValue() {
        return (
            this.oauthFlowTestOrgDomain +
            '.my.salesforce.com/identity/app/AppInstallApprovalPage.apexp?app_id=' +
            this.jwtKPAppId +
            '&app_org_id=' +
            this.jwtKPAppOrgId
        );
    }

    get currentStepVal() {
        return this.currentStep.value;
    }

    get displayNewButton() {
        return this.selectedOauthFlow === 'device';
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

    get isCredentialsFlowSelected() {
        return this.selectedOauthFlow === 'creds';
    }

    get isCredentialsOrJWTFlowSelected() {
        return (
            this.selectedOauthFlow === 'creds' ||
            this.selectedOauthFlow.includes('jwt')
        );
    }

    get isCredentialsOrJWTOrWebFlowSelected() {
        return (
            this.selectedOauthFlow === 'creds' ||
            this.selectedOauthFlow.includes('jwt') ||
            this.selectedOauthFlow === 'web'
        );
    }

    get isJWTAdminKeyFlowSelected() {
        return this.selectedOauthFlow === 'jwt_ak';
    }

    get isJWTFlowSelected() {
        return this.selectedOauthFlow.includes('jwt');
    }

    get isJWTKeyPackagedFlowSelected() {
        return this.selectedOauthFlow === 'jwt_kp';
    }

    get isLoading() {
        return this._isLoading;
    }

    set isLoading(val) {
        this._isLoading = val;
    }

    get isUserDetailsStep() {
        return this.currentStep.value === 'userDetailsStep';
    }

    get isWebFlowSelected() {
        return this.selectedOauthFlow === 'web';
    }

    get oauthOptions() {
        return OAUTH_OPTIONS;
    }

    get steps() {
        return STEPS;
    }

    connectedCallback() {
        this.refreshAuthorizedUsers();
        this.fetchCAInfo();
        this.fetchOrgDomain();
        this.fetchCurrentUser();
    }

    async awaitAuthValidation(numAttempts) {
        numAttempts = numAttempts || 0;
        if (numAttempts >= MAX_VALIDATION_ATTEMPTS) {
            console.error(
                'Something went wrong validating authorization - please try again!'
            );
        }
        if (this.authVerified) {
            return;
        }
        const cmdtUpsertMethod = this.selectedCMDTUpsertMethod;
        const domain = this.orgDomain;
        const deviceCode = this.deviceCode;
        const [error, results] = await safeAwait(
            validatePendingDeviceFlowAuthorization({ cmdtUpsertMethod, domain, deviceCode })
        );
        if (error) {
            console.error(error.body.message);
        }
        if (results.is_authorized) {
            return this.handleSuccessfulAuthorization();
        }
        window.setTimeout(() => {
            return this.awaitAuthValidation(numAttempts + 1);
        }, VALIDATION_DELAY);
    }

    async fetchCAInfo() {
        const [error, results] = await safeAwait(fetchConnectedAppInfo());
        if (error) {
            console.error(error.body.message);
            return;
        }
        this.caInfoByName = results;
        this.clientCredentialsAppId = this.caInfoByName.PLC_Credentials_Flow.id;
        this.clientCredentialsAppOrgId =
            this.caInfoByName.PLC_Credentials_Flow.org_id;
        this.jwtKPAppId = this.caInfoByName.PLC_JWT_Key_Packaged_Flow.id;
        this.jwtKPAppOrgId = this.caInfoByName.PLC_JWT_Key_Packaged_Flow.org_id;
        this.webFlowServerDomain =
            this.caInfoByName.PLC_Web_Server_Flow.server_domain;
    }

    async fetchCurrentUser() {
        const [error, results] = await safeAwait(fetchCurrentUsername());
        if (error) {
            console.error(error.body.message);
            return;
        }
        this.oauthFlowTestUsername = results;
    }

    async fetchDeviceFlowAuthCodes() {
        const cmdtUpsertMethod = this.selectedCMDTUpsertMethod;
        const domain = this.orgDomain;
        const [error, results] = await safeAwait(
            fetchDeviceFlowAuthCodes({ cmdtUpsertMethod, domain })
        );
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
            results.indexOf('.my.', domainStart)
        );
        this.oauthFlowTestOrgDomain = this.orgDomain;
    }

    handleAddNewOauthEnabledUser() {
        const modal = this.template.querySelector('c-custom-modal');
        if (modal) {
            modal.openModal();
        }
    }

    async handleCredentialsFlowTestOrgDomainConnection() {
        const cmdtUpsertMethod = this.selectedCMDTUpsertMethod;
        const domain = this.oauthFlowTestOrgDomain;
        const [error, results] = await safeAwait(
            testCredentialsFlowOrgDomainConnection({
                cmdtUpsertMethod,
                domain
            })
        );
        if (error || results.error) {
            console.error(
                error
                    ? error.body.message
                    : results.error + ' ' + results.error_description
            );
            const showToastEvent = new ShowToastEvent({
                message:
                    'Could not connect to org domain via Credentials flow; please ensure connected app is installed & configured!',
                title: 'Test Unsuccessful',
                variant: 'error'
            });
            this.dispatchEvent(showToastEvent);
            return;
        }
        const showToastEvent = new ShowToastEvent({
            message:
                'Successfully connected to org domain via Credentials flow!',
            title: 'Test Successful',
            variant: 'success'
        });
        this.dispatchEvent(showToastEvent);
        this.refreshAuthorizedUsers();
    }

    async handleJWTFlowTestOrgDomainConnection() {
        const certName = this.oauthFlowTestCertName;
        const cmdtUpsertMethod = this.selectedCMDTUpsertMethod;
        const consumerKey = this.oauthFlowTestConsumerKey;
        const domain = this.oauthFlowTestOrgDomain;
        const username = this.oauthFlowTestUsername;
        let params = {
            cmdtUpsertMethod,
            domain,
            username
        };
        if (this.selectedOauthFlow === 'jwt_ak') {
            params.certName = certName;
            params.consumerKey = consumerKey;
        }
        params.flow = this.selectedOauthFlow;
        const [error, results] = await safeAwait(
            testJWTFlowOrgDomainConnection({
                params
            })
        );
        if (error || results.error) {
            console.error(
                error
                    ? error.body.message
                    : results.error + ' ' + results.error_description
            );
            const showToastEvent = new ShowToastEvent({
                message:
                    'Could not connect to org domain via JWT flow; please ensure connected app is installed & user is pre-authorized!',
                title: 'Test Unsuccessful',
                variant: 'error'
            });
            this.dispatchEvent(showToastEvent);
            return;
        }
        const showToastEvent = new ShowToastEvent({
            message: 'Successfully connected to org domain via JWT flow!',
            title: 'Test Successful',
            variant: 'success'
        });
        this.dispatchEvent(showToastEvent);
        this.refreshAuthorizedUsers();
    }

    handleOauthFlowTestCertNameChange(event) {
        this.oauthFlowTestCertName = event.detail.value;
    }

    handleOauthFlowTestConsumerKeyChange(event) {
        this.oauthFlowTestConsumerKey = event.detail.value;
    }

    handleOauthFlowTestOrgDomainConnection() {
        if (this.selectedOauthFlow.includes('jwt')) {
            this.handleJWTFlowTestOrgDomainConnection();
        } else if (this.selectedOauthFlow === 'creds') {
            this.handleCredentialsFlowTestOrgDomainConnection();
        } else if (this.selectedOauthFlow === 'web') {
            this.handleWebFlowAuthorizeOrgDomainConnection();
        }
    }

    handleOauthFlowTestOrgDomainChange(event) {
        this.oauthFlowTestOrgDomain = event.detail.value;
    }

    handleOauthFlowTestUsernameChange(event) {
        this.oauthFlowTestUsername = event.detail.value;
    }

    handleDomainChange(event) {
        this.orgDomain = event.detail.value;
    }

    handleDone() {
        const modal = this.template.querySelector('c-custom-modal');
        if (modal) {
            modal.closeModal();
            this.refreshAuthorizedUsers();
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
                this.isLoading = true;
                const cmdtUpsertMethod = this.selectedCMDTUpsertMethod;
                const oauthFlow = this.selectedOauthFlow;
                const usernamesToRevoke = selectedRows.map(
                    (item) => item.username
                );
                const [error] = await safeAwait(
                    revokeOAuthEnabledUserAccess({
                        cmdtUpsertMethod,
                        oauthFlow,
                        usernamesToRevoke
                    })
                );
                if (error) {
                    console.error(error.body.message);
                    return;
                }
                this.authorizedUsers = this.authorizedUsers.filter(
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

    handleSelectCMDTUpsertMethod(event) {
        this.selectedCMDTUpsertMethod = event.detail.value;
    }

    handleSelectOauthFlow(event) {
        this.selectedOauthFlow = event.detail.value;
        this.refreshAuthorizedUsers();
    }

    handleSuccessfulAuthorization() {
        // Delay displaying success message to allow time for CMDT to deploy to org
        window.setTimeout(() => {
            this.authVerified = true;
            const showToastEvent = new ShowToastEvent({
                message: 'Successfully created new OAuth enabled user!',
                title: 'Authorization Verified',
                variant: 'success'
            });
            this.dispatchEvent(showToastEvent);
        }, SUCCESS_DELAY);
    }

    handleRefreshTable() {
        this.refreshAuthorizedUsers();
    }

    async handleWebFlowAuthorizeOrgDomainConnection() {
        const source = encodeURIComponent(this.orgDomainExternalUrl);
        const target = encodeURIComponent(
            'https://' + this.oauthFlowTestOrgDomain + '.my.salesforce.com'
        );
        const webFlowServerUrl =
            this.webFlowServerDomain +
            '?source=' +
            source +
            '&target=' +
            target +
            '&cmdtUpsertMethod=' +
            this.selectedCMDTUpsertMethod;
        window.open(webFlowServerUrl, '_blank').focus();
    }

    async refreshAuthorizedUsers() {
        this.isLoading = true;
        const params = {
            oauthFlow: this.selectedOauthFlow
        };
        const [error, results] = await safeAwait(fetchAuthorizedUsers(params));
        if (error) {
            console.error(error.body.message);
        }
        this.authorizedUsers = results;
        this.refreshTableRows();
    }

    refreshTableRows() {
        this.rows = this.authorizedUsers.map((item) => {
            const domainPrefix = 'https://';
            const domainStart =
                item.domain.indexOf(domainPrefix) + domainPrefix.length;
            const domain = item.domain.substring(
                domainStart,
                item.domain.indexOf('.my.', domainStart)
            );
            return {
                domain,
                username: item.username,
                usernameForDisplay: item.usernameForDisplay
            };
        });
        this.isLoading = false;
    }
}
