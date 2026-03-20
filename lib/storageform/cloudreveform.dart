import 'package:flutter/material.dart';
import 'package:lumina/event_bus.dart';
import 'package:lumina/proto/lumina.pbgrpc.dart';
import 'package:lumina/state_model.dart';
import 'package:lumina/storage/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/global.dart';
import 'package:lumina/theme.dart';

class CloudreveForm extends StatefulWidget {
  const CloudreveForm({Key? key}) : super(key: key);

  @override
  CloudreveFormState createState() => CloudreveFormState();
}

class CloudreveFormState extends State<CloudreveForm> {
  @protected
  final GlobalKey _formKey = GlobalKey<FormState>();
  TextEditingController? serverController;
  TextEditingController? emailController;
  TextEditingController? passwordController;
  TextEditingController? rootPathController;
  bool testSuccess = false;
  String? errormsg;
  String currentPath = "";
  bool requires2FA = false;
  String? sessionId;
  TextEditingController? otpController;

  @override
  void initState() {
    super.initState();
    serverController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    rootPathController = TextEditingController();
    otpController = TextEditingController();
    SharedPreferences.getInstance().then((prefs) {
      serverController!.text = prefs.getString('cloudreve_server') ?? "";
      emailController!.text = prefs.getString('cloudreve_email') ?? "";
      passwordController!.text = prefs.getString('cloudreve_password') ?? "";
      rootPathController!.text = prefs.getString('cloudreve_root_path') ?? "";
    });
  }

  Future<bool> checkCloudreve() async {
    final server = serverController!.text;
    final email = emailController!.text;
    final password = passwordController!.text;
    if (server.isEmpty || email.isEmpty || password.isEmpty) {
      return false;
    }
    try {
      final rsp = await storage.cli.setDriveCloudreve(SetDriveCloudrveRequest(
          server: server, email: email, password: password));
      if (!rsp.success) {
        setState(() {
          errormsg = rsp.message;
        });
        return false;
      }
      final rsp2 = await storage.cli
          .listDriveCloudrveDir(ListDriveClourdreveDirRequest());
      if (!rsp2.success) {
        setState(() {
          errormsg = rsp2.message;
        });
        return false;
      }
    } catch (e) {
      setState(() {
        errormsg = e.toString();
      });
      return false;
    }
    return true;
  }

  Future<List<String>> getRootPath(String dir) async {
    final rsp = await storage.cli
        .listDriveCloudrveDir(ListDriveClourdreveDirRequest(dir: dir));
    if (!rsp.success) {
      setState(() {
        errormsg = rsp.message;
      });
      return [];
    }
    return rsp.dirs;
  }

  Future<void> testStorage() async {
    final server = serverController!.text;
    final email = emailController!.text;
    final password = passwordController!.text;
    final rootPath = rootPathController!.text;
    try {
      final rsp = await storage.cli.setDriveCloudreve(SetDriveCloudrveRequest(
          server: server,
          email: email,
          password: password,
          root: rootPath));
      if (rsp.require2fa) {
        setState(() {
          requires2FA = true;
          sessionId = rsp.sessionId;
          errormsg = null;
        });
        return;
      }
      if (!rsp.success) {
        setState(() {
          errormsg = rsp.message;
        });
        return;
      } else {
        setState(() {
          testSuccess = true;
        });
      }
    } catch (e) {
      setState(() {
        errormsg = e.toString();
      });
      return;
    }
  }

  Future<void> verify2FA() async {
    final server = serverController!.text;
    final email = emailController!.text;
    final password = passwordController!.text;
    final rootPath = rootPathController!.text;
    final otp = otpController!.text;
    if (otp.isEmpty || sessionId == null) return;
    try {
      final rsp = await storage.cli.setDriveCloudreve(SetDriveCloudrveRequest(
          server: server,
          email: email,
          password: password,
          root: rootPath,
          otp: otp,
          sessionId: sessionId));
      if (!rsp.success) {
        setState(() {
          errormsg = rsp.message;
        });
        return;
      }
      setState(() {
        testSuccess = true;
        requires2FA = false;
      });
    } catch (e) {
      setState(() {
        errormsg = e.toString();
      });
    }
  }

  void showErrorDialog(String msg) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.connectFailed),
        content: Text(msg),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextFormField(
              controller: serverController,
              obscureText: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: l10n.cloudreveServer,
                helperText: "eg: https://cloud.example.com",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextFormField(
              controller: emailController,
              obscureText: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: l10n.cloudreveEmail,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextFormField(
              controller: passwordController,
              obscureText: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: l10n.cloudrevePassword,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextFormField(
              controller: rootPathController,
              obscureText: false,
              enableInteractiveSelection: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: l10n.rootPath,
                helperText: "eg: /photos",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.open_in_browser),
                  onPressed: () {
                    checkCloudreve().then((available) {
                      if (!available) {
                        showErrorDialog(errormsg ?? l10n.connectFailed);
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => rootPathDialog(),
                        );
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          if (requires2FA) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                l10n.cloudreve2faRequired,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: TextFormField(
                controller: otpController,
                obscureText: false,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: l10n.cloudreveOtp,
                  helperText: l10n.cloudreveOtpHint,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!requires2FA)
                OutlinedButton(
                  onPressed: () {
                    testStorage().then((value) {
                      if (testSuccess) {
                        SnackBarManager.showSnackBar(l10n.testSuccess);
                      } else if (!requires2FA) {
                        showErrorDialog(errormsg ?? l10n.connectFailed);
                      }
                    });
                  },
                  child: Text(l10n.testStorage),
                ),
              if (requires2FA)
                OutlinedButton(
                  onPressed: () {
                    verify2FA().then((_) {
                      if (testSuccess) {
                        SnackBarManager.showSnackBar(l10n.testSuccess);
                      } else {
                        showErrorDialog(errormsg ?? l10n.connectFailed);
                      }
                    });
                  },
                  child: Text(l10n.cloudreveVerify),
                ),
              const SizedBox(width: AppSpacing.md),
              FilledButton(
                onPressed: testSuccess
                    ? () {
                        final server = serverController!.text;
                        final email = emailController!.text;
                        final password = passwordController!.text;
                        final rootPath = rootPathController!.text;
                        SharedPreferences.getInstance().then((value) {
                          value.setString('cloudreve_server', server);
                          value.setString('cloudreve_email', email);
                          value.setString('cloudreve_password', password);
                          value.setString('cloudreve_root_path', rootPath);
                          value.setString(
                              'drive', driveName[Drive.cloudreve]!);
                        });
                        settingModel.setRemoteStorageSetted(true);
                        assetModel.remoteLastError = null;
                        eventBus.fire(RemoteRefreshEvent());
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget rootPathDialog() {
    currentPath = "/";
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          child: SizedBox(
            height: 500,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Text(
                    l10n.selectRoot,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${l10n.currentPath}: $currentPath",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const Divider(indent: 20, endIndent: 20),
                FutureBuilder(
                  future: getRootPath(currentPath),
                  builder: (context, AsyncSnapshot<List<String>> snapshot) {
                    if (snapshot.hasData) {
                      return Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            return InkWell(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(25, 8, 25, 8),
                                child: Text(
                                  snapshot.data![index],
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              onTap: () {
                                setDialogState(() {
                                  if (currentPath == "") {
                                    currentPath = snapshot.data![index];
                                  } else {
                                    currentPath =
                                        "$currentPath${snapshot.data![index]}/";
                                  }
                                });
                              },
                            );
                          },
                        ),
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
                const Divider(indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        child: Text(l10n.cancel),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: AppSpacing.md),
                      FilledButton(
                        child: Text(l10n.save),
                        onPressed: () {
                          rootPathController!.text = currentPath;
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
