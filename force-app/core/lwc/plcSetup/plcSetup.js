import { LightningElement, track } from 'lwc';

import fetchAuthenticatedUsers from '@salesforce/apex/SetupController.fetchAuthenticatedUsers';

import { safeAwait } from 'c/plcUtils';

const AUTH_USER_COLUMNS = [
    { label: 'Domain', fieldName: 'domain', type: 'text' },
    { label: 'User', fieldName: 'usernameForDisplay', type: 'text' },
    { label: 'Username', fieldName: 'username', type: 'text' }
];

const OAUTH_OPTIONS = [
    { label: 'Credentials', value: 'credentials' },
    { label: 'Device', value: 'device' },
    { label: 'JWT (Packaged Private Key)', value: 'jwtPackagedKey' },
    { label: 'JWT (Admin-Provided Private Key', value: 'jwtAdminProvidedKey' },
    { label: 'Web Server', value: 'web' }
];

export default class PlcSetup extends LightningElement {
    authenticatedUsers = [];
    columns = AUTH_USER_COLUMNS;
    selectedOauthFlow = 'device';
    @track rows = [];

    get displayAuthUserTable() {
        return this.selectedOauthFlow !== 'web';
    }

    get oauthOptions() {
        return OAUTH_OPTIONS;
    }

    connectedCallback() {
        this.refreshAuthenticatedUsers();
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

    handleSelectOauthFlow(event) {
        this.selectedOauthFlow = event.detail.value;
        this.refreshAuthenticatedUsers();
    }
}
