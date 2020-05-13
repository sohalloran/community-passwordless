import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import passwordless from '@salesforce/apex/PersistentLoginController.passwordlessLWC';
import confirm from '@salesforce/apex/PersistentLoginController.confirm';


export default class Passwordlesslogin extends NavigationMixin(LightningElement) {

  username = '';
  code = '';
  identifier = '';
  userId = '';

  cancel(event) {
    this.identifier = '';
  }

  handleChange(event) {
    if (event.target.label === 'Username') {
      this.username = event.target.value;
    }
    if (event.target.label === 'Code') {
      this.code = event.target.value;
    }
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
        this[NavigationMixin.Navigate]({
          type: 'standard__webPage',
          attributes: {
            url: result
          }
        });
      })
      .catch(error => {
        console.log(error);
      })

  }
}
