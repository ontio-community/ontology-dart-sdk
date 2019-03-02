import '../crypto/shim.dart';
import 'account.dart';
import 'identity.dart';

class Wallet {
  String name;
  String version;
  String createTime;
  ScryptParams scrypt;
  List<Identity> identities = [];
  List<Account> accounts = [];

  String defaultOntid;
  String defaultAccountAddress;
  String extra;

  Wallet(this.name, {this.version = '1.0', this.createTime, this.scrypt}) {
    createTime = createTime ?? DateTime.now().toIso8601String();
    scrypt = scrypt ?? ScryptParams.defaultParams;
  }

  Wallet.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    createTime = json['createTime'];
    version = json['version'];
    scrypt = ScryptParams.fromJson(json['scrypt']);
    extra = json['extra'];

    defaultOntid = json['defaultOntid'];
    defaultAccountAddress = json['defaultAccountAddress'];

    List<dynamic> identities = json['identities'] ?? [];
    identities.forEach((id) => this.identities.add(Identity.fromJson(id)));

    List<dynamic> accounts = json['accounts'] ?? [];
    accounts.forEach((acc) => this.accounts.add(Account.fromJson(acc)));
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'defaultOntid': defaultOntid,
        'defaultAccountAddress': defaultAccountAddress,
        'createTime': createTime,
        'version': version,
        'scrypt': scrypt,
        'extra': extra,
        'identities': identities,
        'accounts': accounts
      };

  bool hasAccount(Account target) {
    return accounts.indexWhere((acc) => acc.address == target.address) != -1;
  }

  bool hasIdentity(Identity target) {
    return identities.indexWhere((id) => id.ontid == target.ontid) != -1;
  }

  addAccount(Account acc) {
    if (hasAccount(acc)) return;
    accounts.add(acc);
  }

  addIdentity(Identity id) {
    if (hasIdentity(id)) return;
    identities.add(id);
  }

  deleteAccount(Account acc) {
    accounts.removeWhere((a) => a.address == acc.address);
  }

  deleteIdentity(Identity id) {
    identities.removeWhere((i) => i.ontid == id.ontid);
  }

  setDefaultAccount(String addr) {
    if (accounts.indexWhere((acc) => acc.address == addr) == -1) return;
    defaultAccountAddress = addr;
  }
}
