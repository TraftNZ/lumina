import 'package:flutter/material.dart';
import 'package:lumina/event_bus.dart';
import 'package:lumina/proto/lumina.pbgrpc.dart';
import 'package:lumina/state_model.dart';
import 'package:lumina/storage/storage.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/global.dart';
import 'package:lumina/theme.dart';

class NFSForm extends StatefulWidget {
  const NFSForm({Key? key}) : super(key: key);

  @override
  NFSFormState createState() => NFSFormState();
}

class NFSFormState extends State<NFSForm> {
  @protected
  final GlobalKey _formKey = GlobalKey<FormState>();
  TextEditingController? urlController;
  TextEditingController? rootPathController;
  bool testSuccess = false;
  String? errormsg;
  String currentPath = "";

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController();
    rootPathController = TextEditingController();
    SharedPreferences.getInstance().then((prefs) {
      final url = prefs.getString("nfs_url");
      final rootPath = prefs.getString("nfs_root_path");
      if (url != null) {
        urlController!.text = url;
      }
      if (rootPath != null) {
        rootPathController!.text = rootPath;
      }
    });
  }

  Future<bool> checkNFS() async {
    final url = urlController!.text;
    if (url.isEmpty) {
      return false;
    }
    try {
      final rsp1 = await storage.cli.setDriveNFS(SetDriveNFSRequest(addr: url));
      if (!rsp1.success) {
        setState(() {
          errormsg = rsp1.message;
        });
        return false;
      }
      final rsp2 = await storage.cli.listDriveNFSDir(ListDriveNFSDirRequest());
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
    final rsp =
        await storage.cli.listDriveNFSDir(ListDriveNFSDirRequest(dir: dir));
    if (!rsp.success) {
      setState(() {
        errormsg = rsp.message;
      });
    }
    return rsp.dirs;
  }

  Future<void> testStorage() async {
    final url = urlController!.text;
    final rootPath = rootPathController!.text;
    if (url.isEmpty || rootPath.isEmpty) {
      setState(() {
        errormsg = "URL or root path is empty";
      });
      return;
    }
    try {
      final rsp = await storage.cli
          .setDriveNFS(SetDriveNFSRequest(addr: url, root: rootPath));
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
                helperText: "eg: nfs.domain.or.ip:/nfs/path",
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
                    checkNFS().then((available) {
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
                        final rootPath = rootPathController!.text;
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.setString("nfs_url", url);
                          prefs.setString("nfs_root_path", rootPath);
                          prefs.setString("drive", driveName[Drive.nfs]!);
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
                                final dirName = snapshot.data![index];
                                setDialogState(() {
                                  if (currentPath == "") {
                                    currentPath = dirName;
                                  } else if (dirName == ".") {
                                    currentPath = path.dirname(currentPath);
                                  } else {
                                    currentPath = "$currentPath$dirName/";
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
