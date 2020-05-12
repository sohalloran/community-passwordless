import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import loginLWC from '@salesforce/apex/PersistentLoginController.loginLWC';
import passwordless from '@salesforce/apex/PersistentLoginController.passwordlessLWC';
import confirm from '@salesforce/apex/PersistentLoginController.confirm';

const COLS = [
  { label: 'Message', fieldName: 'Message__c', initialWidth: 100 },
  { label: 'Id', fieldName: 'Id' },
  {
    type: "button", typeAttributes: {
      label: 'Positive',
      name: 'Positive',
      title: 'Positive',
      disabled: false,
      value: 'Positive',
      iconPosition: 'left',
      initialWidth: 10
    }
  },
  {
    type: "button", typeAttributes: {
      label: 'Neutral',
      name: 'Neutral',
      title: 'Neutral',
      disabled: false,
      value: 'Neutral',
      iconPosition: 'left',
      initialWidth: 10
    }
  },
  {
    type: "button", typeAttributes: {
      label: 'Negative',
      name: 'Negative',
      title: 'Negative',
      disabled: false,
      value: 'Negative',
      iconPosition: 'left',
      initialWidth: 10
    }
  }
];


export default class Passwordlesslogin extends NavigationMixin(LightningElement) {


  @track username = '';
  @track password = '';
  @track code = '';
  @track identifier = '';
  @track userId = '';
  @track sentiment;
  @track object = 'Account';
  @track action = 'new';
  @track columns = COLS;

  addMessageToUser(evt) {
    console.log('addMessageToUser');
    try {
      this[NavigationMixin.Navigate]({
        type: 'standard__objectPage',
        attributes: {
          objectApiName: this.object,
          actionName: this.action
        },
        state: {
          nooverride: '1',
          name: 'demo'
        }
      });
      console.log(i);
    } catch (e) {
      console.error(e);
    }
  }

  handleChange(event) {
    if (event.target.label === 'Username') {
      this.username = event.target.value;
    }
    if (event.target.label === 'Password') {
      this.password = event.target.value;
    }
    if (event.target.label === 'Code') {
      this.code = event.target.value;
    }
    if (event.target.label === 'Object') {
      this.object = event.target.value;
    }
    if (event.target.label === 'Action') {
      this.action = event.target.value;
    }
  }
  login() {
    loginLWC({ username: this.username, password: this.password, startUrl: '/' })
      .then(result => {
        const data = JSON.parse(result);
        this.setCookie(data.tokenEndpoint.replace('/s/', '/'), data.JWT);
        window.location.href = data.retURL;
      })
      .catch(error => {
        let data = JSON.parse(result);
        console.log(data.error);
      })
  }
  JWTLogin() {
    const { tokenEndpoint, token } = this.getCookieItems();
    fetch(tokenEndpoint, {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      method: "POST",
      body: 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + token
    })
      .then(result => {
        return result.json();
      }).then(result => {
        window.location.href = result.sfdc_community_url + '/secur/frontdoor.jsp?sid=' + result.access_token;
      });
  }
  passwordLessService() {
    const vf = 'https://sdodemo-main-166ce2cf6b6-16d25b89998.force.com/consumer/Redirect?userId=' + this.userId + '&identifier=' + this.identifier + '&code=' + this.code + '&startUrl=/'
    window.location.href = vf;
  }
  passwordlessLogin() {
    console.log(this.username);
    passwordless({ input: this.username, startUrl: '/' })
      .then(result => {
        console.log(result);
        let data = JSON.parse(result);
        this.userId = data.userId;
        this.identifier = data.identifier;
      })
      .catch(error => {
        console.log(error);
      })

  }
  confirmCode() {
    confirm({ userId: this.userId, identifier: this.identifier, code: this.code, startUrl: '/' })
      .then(result => {
        console.log(result);
        window.open(result, "MsgWindow", "width=500,height=500");
      })
      .catch(error => {
        console.log(error);
      })

  }
  setCookie(tokenEndpoint, token) {
    const date = new Date();
    date.setTime(date.getTime() + (365 * 24 * 60 * 60 * 1000));
    const expires = "; expires=" + date.toGMTString();
    document.cookie = "tokenEndpoint=" + tokenEndpoint.replace('/s/', '/') + "; token=" + token + expires + "; path=/";
  }
  getCookieItems() {
    const token = document.cookie.split('token=')[1].split(';')[0];
    const tokenEndpoint = document.cookie.split('tokenEndpoint=')[1].split(';')[0];
    return { tokenEndpoint, token };
  }
  popout() {
    window.open("https://www.w3schools.com", "MsgWindow", "width=500,height=500");
  }
  connectedCallback() {
    this.sentiment = [
      { Id: '0001', Human_Sentiment__c: '0001', Message__c: 'Some message 1' },
      { Id: '0002', Human_Sentiment__c: '0002', Message__c: 'Some message 2' },
      { Id: '0003', Human_Sentiment__c: '0003', Message__c: 'Some message 3' }
    ]
  }
  callRowAction(event) {
    const recId = event.detail.row.Id;
    const actionName = event.detail.action.name;
    console.log('actionName', actionName)
    console.log('recId', recId)
  }
}
