import 'package:flutter/material.dart';
import 'package:lumina/event_bus.dart';
import 'package:lumina/proto/lumina.pbgrpc.dart';
import 'package:lumina/state_model.dart';
import 'package:lumina/storage/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/global.dart';
import 'package:lumina/theme.dart';

class S3Form extends StatefulWidget {
  const S3Form({Key? key}) : super(key: key);

  @override
  S3FormState createState() => S3FormState();
}

class S3FormState extends State<S3Form> {
  @protected
  final GlobalKey _formKey = GlobalKey<FormState>();
  TextEditingController? endpointController;
  TextEditingController? regionController;
  TextEditingController? accessKeyIdController;
  TextEditingController? secretAccessKeyController;
  TextEditingController? bucketController;
  TextEditingController? rootPathController;
  bool testSuccess = false;
  String? errormsg;

  @override
  void initState() {
    super.initState();
    endpointController = TextEditingController();
    regionController = TextEditingController();
    accessKeyIdController = TextEditingController();
    secretAccessKeyController = TextEditingController();
    bucketController = TextEditingController();
    rootPathController = TextEditingController();
    SharedPreferences.getInstance().then((prefs) {
      endpointController!.text = prefs.getString('s3_endpoint') ?? "";
      regionController!.text = prefs.getString('s3_region') ?? "";
      accessKeyIdController!.text = prefs.getString('s3_access_key_id') ?? "";
      secretAccessKeyController!.text =
          prefs.getString('s3_secret_access_key') ?? "";
      bucketController!.text = prefs.getString('s3_bucket') ?? "";
      rootPathController!.text = prefs.getString('s3_root_path') ?? "";
    });
  }

  Future<void> testStorage() async {
    final endpoint = endpointController!.text;
    final region = regionController!.text;
    final accessKeyId = accessKeyIdController!.text;
    final secretAccessKey = secretAccessKeyController!.text;
    final bucket = bucketController!.text;
    final rootPath = rootPathController!.text;
    try {
      final rsp = await storage.cli.setDriveS3(SetDriveS3Request(
        endpoint: endpoint,
        region: region,
        accessKeyId: accessKeyId,
        secretAccessKey: secretAccessKey,
        bucket: bucket,
        root: rootPath,
      ));
      if (!rsp.success) {
        setState(() {
          errormsg = rsp.message;
          testSuccess = false;
        });
        return;
      }
      setState(() {
        testSuccess = true;
      });
    } catch (e) {
      setState(() {
        errormsg = e.toString();
        testSuccess = false;
      });
    }
  }

  Future<void> browseBuckets() async {
    final endpoint = endpointController!.text;
    final region = regionController!.text;
    final accessKeyId = accessKeyIdController!.text;
    final secretAccessKey = secretAccessKeyController!.text;
    if (accessKeyId.isEmpty || secretAccessKey.isEmpty) {
      showErrorDialog("Access Key ID and Secret Access Key are required");
      return;
    }
    try {
      // Set drive first so the server has credentials
      final setRsp = await storage.cli.setDriveS3(SetDriveS3Request(
        endpoint: endpoint,
        region: region,
        accessKeyId: accessKeyId,
        secretAccessKey: secretAccessKey,
        bucket: bucketController!.text.isNotEmpty
            ? bucketController!.text
            : 'temp',
      ));
      if (!setRsp.success) {
        showErrorDialog(setRsp.message);
        return;
      }
      final rsp =
          await storage.cli.listDriveS3Buckets(ListDriveS3BucketsRequest());
      if (!rsp.success) {
        showErrorDialog(rsp.message);
        return;
      }
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) => Dialog(
          child: SizedBox(
            height: 400,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Text(
                    l10n.s3Bucket,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(indent: 20, endIndent: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: rsp.buckets.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(25, 8, 25, 8),
                          child: Text(
                            rsp.buckets[index],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        onTap: () {
                          bucketController!.text = rsp.buckets[index];
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                  child: OutlinedButton(
                    child: Text(l10n.cancel),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      showErrorDialog(e.toString());
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
              controller: endpointController,
              decoration: InputDecoration(
                labelText: l10n.s3Endpoint,
                helperText: "eg: https://s3.amazonaws.com",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextFormField(
              controller: regionController,
              decoration: InputDecoration(
                labelText: '${l10n.s3Region} (${l10n.optional})',
                helperText: "eg: us-east-1",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextFormField(
              controller: accessKeyIdController,
              decoration: InputDecoration(
                labelText: l10n.s3AccessKeyId,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextFormField(
              controller: secretAccessKeyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.s3SecretAccessKey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextFormField(
              controller: bucketController,
              decoration: InputDecoration(
                labelText: l10n.s3Bucket,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: browseBuckets,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextFormField(
              controller: rootPathController,
              decoration: InputDecoration(
                labelText: l10n.rootPath,
                helperText: "eg: photos/",
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  testStorage().then((_) {
                    if (testSuccess) {
                      SnackBarManager.showSnackBar(l10n.testSuccess);
                    } else {
                      showErrorDialog(errormsg ?? "Unknown error");
                    }
                  });
                },
                child: Text(l10n.testStorage),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton(
                onPressed: testSuccess
                    ? () {
                        final endpoint = endpointController!.text;
                        final region = regionController!.text;
                        final accessKeyId = accessKeyIdController!.text;
                        final secretAccessKey =
                            secretAccessKeyController!.text;
                        final bucket = bucketController!.text;
                        final rootPath = rootPathController!.text;
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.setString('s3_endpoint', endpoint);
                          prefs.setString('s3_region', region);
                          prefs.setString('s3_access_key_id', accessKeyId);
                          prefs.setString(
                              's3_secret_access_key', secretAccessKey);
                          prefs.setString('s3_bucket', bucket);
                          prefs.setString('s3_root_path', rootPath);
                          prefs.setString('drive', driveName[Drive.s3]!);
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
}
