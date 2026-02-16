import 'package:flutter/material.dart';
import 'package:lumina/event_bus.dart';
import 'package:lumina/proto/lumina.pbgrpc.dart';
import 'package:lumina/state_model.dart';
import 'package:lumina/storage/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/global.dart';
import 'package:lumina/theme.dart';

class WebDavForm extends StatefulWidget {
  const WebDavForm({Key? key}) : super(key: key);

  @override
  WebDavFormState createState() => WebDavFormState();
}

class WebDavFormState extends State<WebDavForm> {
  @protected
  final GlobalKey _formKey = GlobalKey<FormState>();
  TextEditingController? urlController;
  TextEditingController? usernameController;
  TextEditingController? passwordController;
  TextEditingController? rootPathController;
  bool testSuccess = false;
  String? errormsg;
  String currentPath = "";

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    rootPathController = TextEditingController();
    SharedPreferences.getInstance().then((prefs) {
      urlController!.text = prefs.getString('webdav_url') ?? "";
      usernameController!.text = prefs.getString('webdav_username') ?? "";
      passwordController!.text = prefs.getString('webdav_password') ?? "";
      rootPathController!.text = prefs.getString('webdav_root_path') ?? "";
    });
  }

  Future<bool> checkWebdav() async {
    final url = urlController!.text;
    final username = usernameController!.text;
    final password = passwordController!.text;
    if (url.isEmpty) {
      return false;
    }
    try {
      final rsp2 = await storage.cli.setDriveWebdav(SetDriveWebdavRequest(
          addr: url, username: username, password: password));
      if (!rsp2.success) {
        setState(() {
          errormsg = rsp2.message;
        });
        return false;
      }
      final rsp3 =
          await storage.cli.listDriveWebdavDir(ListDriveWebdavDirRequest());
      if (!rsp3.success) {
        setState(() {
          errormsg = rsp3.message;
        });
        return false;
      }
    } catch (e) {
      setState(() {
        errormsg = e.toString();
      });
    }
    return true;
  }

  Future<List<String>> getRootPath(String dir) async {
    final rsp = await storage.cli
        .listDriveWebdavDir(ListDriveWebdavDirRequest(dir: dir));
    if (!rsp.success) {
      setState(() {
        errormsg = rsp.message;
      });
      return [];
    }
    return rsp.dirs;
  }

  Future<void> testStorage() async {
    final url = urlController!.text;
    final username = usernameController!.text;
    final password = passwordController!.text;
    final rootPath = rootPathController!.text;
    try {
      final rsp = await storage.cli.setDriveWebdav(SetDriveWebdavRequest(
          addr: url, username: username, password: password, root: rootPath));
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
              controller: urlController,
              obscureText: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: "URL",
                helperText: "eg: https://your.domain:port",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextFormField(
              controller: usernameController,
              obscureText: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: '${l10n.username} (${l10n.optional})',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextFormField(
              controller: passwordController,
              obscureText: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: '${l10n.password} (${l10n.optional})',
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
                helperText: "eg: /path/photo",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.open_in_browser),
                  onPressed: () {
                    checkWebdav().then((available) {
                      if (!available) {
                        showErrorDialog(errormsg!);
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
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  testStorage().then((value) {
                    if (testSuccess) {
                      SnackBarManager.showSnackBar(l10n.testSuccess);
                    } else {
                      showErrorDialog(errormsg!);
                    }
                  });
                },
                child: Text(l10n.testStorage),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton(
                onPressed: testSuccess
                    ? () {
                        final url = urlController!.text;
                        final username = usernameController!.text;
                        final password = passwordController!.text;
                        final rootPath = rootPathController!.text;
                        SharedPreferences.getInstance().then((value) {
                          value.setString('webdav_url', url);
                          value.setString('webdav_username', username);
                          value.setString('webdav_password', password);
                          value.setString('webdav_root_path', rootPath);
                          value.setString('drive', driveName[Drive.webDav]!);
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
                                  style: Theme.of(context).textTheme.bodyMedium,
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
