/* eslint-disable consistent-return */
import { LightningElement, track } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import fetchAuthorizedUsers from '@salesforce/apex/SetupController.fetchAuthorizedUsers';
import fetchPageLayoutIncludedFields from '@salesforce/apex/SetupController.fetchPageLayoutIncludedFields';

import { safeAwait } from 'c/plcUtils';

const AUTH_METHOD_OPTIONS = [
    { label: 'User Session Id', value: 'session_id' },
    { label: 'User Session Id from Visualforce', value: 'session_id_from_vf' },
    { label: 'OAuth (Credentials)', value: 'creds' },
    { label: 'OAuth (Device)', value: 'device' },
    { label: 'OAuth (JWT - Packaged Private Key)', value: 'jwt_kp' },
    { label: 'OAuth (JWT - Admin-Provided Private Key)', value: 'jwt_ak' },
    { label: 'OAuth (Web Server)', value: 'web' }
];

const FIELD_TABLE_COLUMNS = [
    { label: 'Field', fieldName: 'field', type: 'text' }
];

export default class PlcComparison extends LightningElement {
    authorizedUsers = [];
    selectedAuthMethod = 'session_id';
    selectedAuthorizedUser;
    objectName = 'Account';
    pageLayoutName = 'Account Layout';
    isLoading;
    columns = FIELD_TABLE_COLUMNS;
    @track rows = [];

    get authMethodOptions() {
        return AUTH_METHOD_OPTIONS;
    }

    get authorizedUserOptions() {
        return this.authorizedUsers.map((el) => {
            return {
                label:
                    el.usernameForDisplay +
                    ' (' +
                    el.domain.split('/services/oauth2/token')[0] +
                    ')',
                value:
                    el.username +
                    ' - ' +
                    el.domain.split('/services/oauth2/token')[0]
            };
        });
    }

    get isOAuthMethodSelected() {
        return !this.selectedAuthMethod.includes('session_id');
    }

    get isObjectInputDisabled() {
        // Currently disabled for the sake of simplicity
        return true;
    }

    get isLayoutInputDisabled() {
        // Currently disabled for the sake of simplicity
        return true;
    }

    get tableHasRows() {
        return this.rows.length > 0;
    }

    handleSelectAuthMethod(event) {
        this.rows = [];
        this.selectedAuthMethod = event.detail.value;
        this.refreshAuthorizedUsers();
    }

    handleSelectAuthorizedUser(event) {
        this.rows = [];
        this.selectedAuthorizedUser = event.detail.value;
    }

    handleObjectNameChange(event) {
        this.rows = [];
        this.objectName = event.detail.value;
    }

    handlePageLayoutNameChange(event) {
        this.rows = [];
        this.pageLayoutNameChange = event.detail.value;
    }

    async handleFetchPageLayoutIncludedFields() {
        this.isLoading = true;
        this.rows = [];
        const params = {
            authMethod: this.selectedAuthMethod,
            domain: this.selectedAuthorizedUser?.split(' - ')[1],
            username: this.selectedAuthorizedUser?.split(' - ')[0],
            objectName: this.objectName,
            pageLayoutName: this.pageLayoutName
        };
        const [error, results] = await safeAwait(
            fetchPageLayoutIncludedFields(params)
        );
        if (error) {
            console.error(error?.body?.message || error);
            const showToastEvent = new ShowToastEvent({
                message:
                    'Could not retrieve page layout included fields. Error: ' +
                    error.body.message,
                title: 'Unsuccessful',
                variant: 'error'
            });
            this.isLoading = false;
            return this.dispatchEvent(showToastEvent);
        }
        this.rows = results.map((item) => {
            return {
                field: item
            };
        });
        this.isLoading = false;
    }

    async refreshAuthorizedUsers() {
        this.isLoading = true;
        const params = {
            oauthFlow: this.selectedAuthMethod
        };
        const [error, results] = await safeAwait(fetchAuthorizedUsers(params));
        if (error) {
            return console.error(error.body.message);
        }
        this.authorizedUsers = results;
        this.isLoading = false;
    }
}
