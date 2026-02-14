// This is a generated file - do not edit.
//
// Generated from proto/img_syncer.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use listByDateRequestDescriptor instead')
const ListByDateRequest$json = {
  '1': 'ListByDateRequest',
  '2': [
    {'1': 'date', '3': 1, '4': 1, '5': 9, '10': 'date'},
    {'1': 'offset', '3': 2, '4': 1, '5': 5, '10': 'offset'},
    {'1': 'maxReturn', '3': 3, '4': 1, '5': 5, '10': 'maxReturn'},
  ],
};

/// Descriptor for `ListByDateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listByDateRequestDescriptor = $convert.base64Decode(
    'ChFMaXN0QnlEYXRlUmVxdWVzdBISCgRkYXRlGAEgASgJUgRkYXRlEhYKBm9mZnNldBgCIAEoBV'
    'IGb2Zmc2V0EhwKCW1heFJldHVybhgDIAEoBVIJbWF4UmV0dXJu');

@$core.Deprecated('Use listByDateResponseDescriptor instead')
const ListByDateResponse$json = {
  '1': 'ListByDateResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'paths', '3': 3, '4': 3, '5': 9, '10': 'paths'},
  ],
};

/// Descriptor for `ListByDateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listByDateResponseDescriptor = $convert.base64Decode(
    'ChJMaXN0QnlEYXRlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZXNzYW'
    'dlGAIgASgJUgdtZXNzYWdlEhQKBXBhdGhzGAMgAygJUgVwYXRocw==');

@$core.Deprecated('Use deleteRequestDescriptor instead')
const DeleteRequest$json = {
  '1': 'DeleteRequest',
  '2': [
    {'1': 'paths', '3': 1, '4': 3, '5': 9, '10': 'paths'},
  ],
};

/// Descriptor for `DeleteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteRequestDescriptor = $convert
    .base64Decode('Cg1EZWxldGVSZXF1ZXN0EhQKBXBhdGhzGAEgAygJUgVwYXRocw==');

@$core.Deprecated('Use deleteResponseDescriptor instead')
const DeleteResponse$json = {
  '1': 'DeleteResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `DeleteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteResponseDescriptor = $convert.base64Decode(
    'Cg5EZWxldGVSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3NhZ2UYAi'
    'ABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use filterNotUploadedRequestInfoDescriptor instead')
const FilterNotUploadedRequestInfo$json = {
  '1': 'FilterNotUploadedRequestInfo',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'date', '3': 2, '4': 1, '5': 9, '10': 'date'},
    {'1': 'id', '3': 3, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `FilterNotUploadedRequestInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filterNotUploadedRequestInfoDescriptor =
    $convert.base64Decode(
        'ChxGaWx0ZXJOb3RVcGxvYWRlZFJlcXVlc3RJbmZvEhIKBG5hbWUYASABKAlSBG5hbWUSEgoEZG'
        'F0ZRgCIAEoCVIEZGF0ZRIOCgJpZBgDIAEoCVICaWQ=');

@$core.Deprecated('Use filterNotUploadedRequestDescriptor instead')
const FilterNotUploadedRequest$json = {
  '1': 'FilterNotUploadedRequest',
  '2': [
    {
      '1': 'photos',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.img_syncer.FilterNotUploadedRequestInfo',
      '10': 'photos'
    },
    {'1': 'isFinished', '3': 2, '4': 1, '5': 8, '10': 'isFinished'},
  ],
};

/// Descriptor for `FilterNotUploadedRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filterNotUploadedRequestDescriptor = $convert.base64Decode(
    'ChhGaWx0ZXJOb3RVcGxvYWRlZFJlcXVlc3QSQAoGcGhvdG9zGAEgAygLMiguaW1nX3N5bmNlci'
    '5GaWx0ZXJOb3RVcGxvYWRlZFJlcXVlc3RJbmZvUgZwaG90b3MSHgoKaXNGaW5pc2hlZBgCIAEo'
    'CFIKaXNGaW5pc2hlZA==');

@$core.Deprecated('Use filterNotUploadedResponseDescriptor instead')
const FilterNotUploadedResponse$json = {
  '1': 'FilterNotUploadedResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'notUploaedIDs', '3': 3, '4': 3, '5': 9, '10': 'notUploaedIDs'},
    {'1': 'isFinished', '3': 4, '4': 1, '5': 8, '10': 'isFinished'},
  ],
};

/// Descriptor for `FilterNotUploadedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filterNotUploadedResponseDescriptor = $convert.base64Decode(
    'ChlGaWx0ZXJOb3RVcGxvYWRlZFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGA'
    'oHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZRIkCg1ub3RVcGxvYWVkSURzGAMgAygJUg1ub3RVcGxv'
    'YWVkSURzEh4KCmlzRmluaXNoZWQYBCABKAhSCmlzRmluaXNoZWQ=');

@$core.Deprecated('Use setDriveSMBRequestDescriptor instead')
const SetDriveSMBRequest$json = {
  '1': 'SetDriveSMBRequest',
  '2': [
    {'1': 'addr', '3': 1, '4': 1, '5': 9, '10': 'addr'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
    {'1': 'share', '3': 4, '4': 1, '5': 9, '10': 'share'},
    {'1': 'root', '3': 5, '4': 1, '5': 9, '10': 'root'},
  ],
};

/// Descriptor for `SetDriveSMBRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveSMBRequestDescriptor = $convert.base64Decode(
    'ChJTZXREcml2ZVNNQlJlcXVlc3QSEgoEYWRkchgBIAEoCVIEYWRkchIaCgh1c2VybmFtZRgCIA'
    'EoCVIIdXNlcm5hbWUSGgoIcGFzc3dvcmQYAyABKAlSCHBhc3N3b3JkEhQKBXNoYXJlGAQgASgJ'
    'UgVzaGFyZRISCgRyb290GAUgASgJUgRyb290');

@$core.Deprecated('Use setDriveSMBResponseDescriptor instead')
const SetDriveSMBResponse$json = {
  '1': 'SetDriveSMBResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `SetDriveSMBResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveSMBResponseDescriptor = $convert.base64Decode(
    'ChNTZXREcml2ZVNNQlJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2'
    'FnZRgCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use listDriveSMBSharesRequestDescriptor instead')
const ListDriveSMBSharesRequest$json = {
  '1': 'ListDriveSMBSharesRequest',
};

/// Descriptor for `ListDriveSMBSharesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveSMBSharesRequestDescriptor =
    $convert.base64Decode('ChlMaXN0RHJpdmVTTUJTaGFyZXNSZXF1ZXN0');

@$core.Deprecated('Use listDriveSMBSharesResponseDescriptor instead')
const ListDriveSMBSharesResponse$json = {
  '1': 'ListDriveSMBSharesResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'shares', '3': 3, '4': 3, '5': 9, '10': 'shares'},
  ],
};

/// Descriptor for `ListDriveSMBSharesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveSMBSharesResponseDescriptor =
    $convert.base64Decode(
        'ChpMaXN0RHJpdmVTTUJTaGFyZXNSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEh'
        'gKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2USFgoGc2hhcmVzGAMgAygJUgZzaGFyZXM=');

@$core.Deprecated('Use listDriveSMBDirRequestDescriptor instead')
const ListDriveSMBDirRequest$json = {
  '1': 'ListDriveSMBDirRequest',
  '2': [
    {'1': 'share', '3': 1, '4': 1, '5': 9, '10': 'share'},
    {'1': 'dir', '3': 2, '4': 1, '5': 9, '10': 'dir'},
  ],
};

/// Descriptor for `ListDriveSMBDirRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveSMBDirRequestDescriptor =
    $convert.base64Decode(
        'ChZMaXN0RHJpdmVTTUJEaXJSZXF1ZXN0EhQKBXNoYXJlGAEgASgJUgVzaGFyZRIQCgNkaXIYAi'
        'ABKAlSA2Rpcg==');

@$core.Deprecated('Use listDriveSMBDirResponseDescriptor instead')
const ListDriveSMBDirResponse$json = {
  '1': 'ListDriveSMBDirResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'dirs', '3': 3, '4': 3, '5': 9, '10': 'dirs'},
  ],
};

/// Descriptor for `ListDriveSMBDirResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveSMBDirResponseDescriptor =
    $convert.base64Decode(
        'ChdMaXN0RHJpdmVTTUJEaXJSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB2'
        '1lc3NhZ2UYAiABKAlSB21lc3NhZ2USEgoEZGlycxgDIAMoCVIEZGlycw==');

@$core.Deprecated('Use setDriveSMBShareRequestDescriptor instead')
const SetDriveSMBShareRequest$json = {
  '1': 'SetDriveSMBShareRequest',
  '2': [
    {'1': 'share', '3': 1, '4': 1, '5': 9, '10': 'share'},
    {'1': 'root', '3': 2, '4': 1, '5': 9, '10': 'root'},
  ],
};

/// Descriptor for `SetDriveSMBShareRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveSMBShareRequestDescriptor =
    $convert.base64Decode(
        'ChdTZXREcml2ZVNNQlNoYXJlUmVxdWVzdBIUCgVzaGFyZRgBIAEoCVIFc2hhcmUSEgoEcm9vdB'
        'gCIAEoCVIEcm9vdA==');

@$core.Deprecated('Use setDriveSMBShareResponseDescriptor instead')
const SetDriveSMBShareResponse$json = {
  '1': 'SetDriveSMBShareResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `SetDriveSMBShareResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveSMBShareResponseDescriptor =
    $convert.base64Decode(
        'ChhTZXREcml2ZVNNQlNoYXJlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCg'
        'dtZXNzYWdlGAIgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use setDriveWebdavRequestDescriptor instead')
const SetDriveWebdavRequest$json = {
  '1': 'SetDriveWebdavRequest',
  '2': [
    {'1': 'addr', '3': 1, '4': 1, '5': 9, '10': 'addr'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
    {'1': 'root', '3': 4, '4': 1, '5': 9, '10': 'root'},
  ],
};

/// Descriptor for `SetDriveWebdavRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveWebdavRequestDescriptor = $convert.base64Decode(
    'ChVTZXREcml2ZVdlYmRhdlJlcXVlc3QSEgoEYWRkchgBIAEoCVIEYWRkchIaCgh1c2VybmFtZR'
    'gCIAEoCVIIdXNlcm5hbWUSGgoIcGFzc3dvcmQYAyABKAlSCHBhc3N3b3JkEhIKBHJvb3QYBCAB'
    'KAlSBHJvb3Q=');

@$core.Deprecated('Use setDriveWebdavResponseDescriptor instead')
const SetDriveWebdavResponse$json = {
  '1': 'SetDriveWebdavResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `SetDriveWebdavResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveWebdavResponseDescriptor =
    $convert.base64Decode(
        'ChZTZXREcml2ZVdlYmRhdlJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbW'
        'Vzc2FnZRgCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use listDriveWebdavDirRequestDescriptor instead')
const ListDriveWebdavDirRequest$json = {
  '1': 'ListDriveWebdavDirRequest',
  '2': [
    {'1': 'dir', '3': 1, '4': 1, '5': 9, '10': 'dir'},
  ],
};

/// Descriptor for `ListDriveWebdavDirRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveWebdavDirRequestDescriptor =
    $convert.base64Decode(
        'ChlMaXN0RHJpdmVXZWJkYXZEaXJSZXF1ZXN0EhAKA2RpchgBIAEoCVIDZGly');

@$core.Deprecated('Use listDriveWebdavDirResponseDescriptor instead')
const ListDriveWebdavDirResponse$json = {
  '1': 'ListDriveWebdavDirResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'dirs', '3': 3, '4': 3, '5': 9, '10': 'dirs'},
  ],
};

/// Descriptor for `ListDriveWebdavDirResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveWebdavDirResponseDescriptor =
    $convert.base64Decode(
        'ChpMaXN0RHJpdmVXZWJkYXZEaXJSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEh'
        'gKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2USEgoEZGlycxgDIAMoCVIEZGlycw==');

@$core.Deprecated('Use setDriveNFSRequestDescriptor instead')
const SetDriveNFSRequest$json = {
  '1': 'SetDriveNFSRequest',
  '2': [
    {'1': 'addr', '3': 1, '4': 1, '5': 9, '10': 'addr'},
    {'1': 'root', '3': 2, '4': 1, '5': 9, '10': 'root'},
  ],
};

/// Descriptor for `SetDriveNFSRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveNFSRequestDescriptor = $convert.base64Decode(
    'ChJTZXREcml2ZU5GU1JlcXVlc3QSEgoEYWRkchgBIAEoCVIEYWRkchISCgRyb290GAIgASgJUg'
    'Ryb290');

@$core.Deprecated('Use setDriveNFSResponseDescriptor instead')
const SetDriveNFSResponse$json = {
  '1': 'SetDriveNFSResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `SetDriveNFSResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveNFSResponseDescriptor = $convert.base64Decode(
    'ChNTZXREcml2ZU5GU1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2'
    'FnZRgCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use listDriveNFSDirRequestDescriptor instead')
const ListDriveNFSDirRequest$json = {
  '1': 'ListDriveNFSDirRequest',
  '2': [
    {'1': 'dir', '3': 1, '4': 1, '5': 9, '10': 'dir'},
  ],
};

/// Descriptor for `ListDriveNFSDirRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveNFSDirRequestDescriptor = $convert
    .base64Decode('ChZMaXN0RHJpdmVORlNEaXJSZXF1ZXN0EhAKA2RpchgBIAEoCVIDZGly');

@$core.Deprecated('Use listDriveNFSDirResponseDescriptor instead')
const ListDriveNFSDirResponse$json = {
  '1': 'ListDriveNFSDirResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'dirs', '3': 3, '4': 3, '5': 9, '10': 'dirs'},
  ],
};

/// Descriptor for `ListDriveNFSDirResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveNFSDirResponseDescriptor =
    $convert.base64Decode(
        'ChdMaXN0RHJpdmVORlNEaXJSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB2'
        '1lc3NhZ2UYAiABKAlSB21lc3NhZ2USEgoEZGlycxgDIAMoCVIEZGlycw==');

@$core.Deprecated('Use setDriveBaiduNetDiskRequestDescriptor instead')
const SetDriveBaiduNetDiskRequest$json = {
  '1': 'SetDriveBaiduNetDiskRequest',
  '2': [
    {'1': 'refreshToken', '3': 1, '4': 1, '5': 9, '10': 'refreshToken'},
    {'1': 'accessToken', '3': 2, '4': 1, '5': 9, '10': 'accessToken'},
    {'1': 'tmpDir', '3': 3, '4': 1, '5': 9, '10': 'tmpDir'},
  ],
};

/// Descriptor for `SetDriveBaiduNetDiskRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveBaiduNetDiskRequestDescriptor =
    $convert.base64Decode(
        'ChtTZXREcml2ZUJhaWR1TmV0RGlza1JlcXVlc3QSIgoMcmVmcmVzaFRva2VuGAEgASgJUgxyZW'
        'ZyZXNoVG9rZW4SIAoLYWNjZXNzVG9rZW4YAiABKAlSC2FjY2Vzc1Rva2VuEhYKBnRtcERpchgD'
        'IAEoCVIGdG1wRGly');

@$core.Deprecated('Use setDriveBaiduNetDiskResponseDescriptor instead')
const SetDriveBaiduNetDiskResponse$json = {
  '1': 'SetDriveBaiduNetDiskResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `SetDriveBaiduNetDiskResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveBaiduNetDiskResponseDescriptor =
    $convert.base64Decode(
        'ChxTZXREcml2ZUJhaWR1TmV0RGlza1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3'
        'MSGAoHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use startBaiduNetdiskLoginRequestDescriptor instead')
const StartBaiduNetdiskLoginRequest$json = {
  '1': 'StartBaiduNetdiskLoginRequest',
  '2': [
    {'1': 'tmpDir', '3': 1, '4': 1, '5': 9, '10': 'tmpDir'},
  ],
};

/// Descriptor for `StartBaiduNetdiskLoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startBaiduNetdiskLoginRequestDescriptor =
    $convert.base64Decode(
        'Ch1TdGFydEJhaWR1TmV0ZGlza0xvZ2luUmVxdWVzdBIWCgZ0bXBEaXIYASABKAlSBnRtcERpcg'
        '==');

@$core.Deprecated('Use startBaiduNetdiskLoginResponseDescriptor instead')
const StartBaiduNetdiskLoginResponse$json = {
  '1': 'StartBaiduNetdiskLoginResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'refreshToken', '3': 3, '4': 1, '5': 9, '10': 'refreshToken'},
    {'1': 'accessToken', '3': 4, '4': 1, '5': 9, '10': 'accessToken'},
    {'1': 'exiresAt', '3': 5, '4': 1, '5': 3, '10': 'exiresAt'},
  ],
};

/// Descriptor for `StartBaiduNetdiskLoginResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startBaiduNetdiskLoginResponseDescriptor =
    $convert.base64Decode(
        'Ch5TdGFydEJhaWR1TmV0ZGlza0xvZ2luUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2'
        'VzcxIYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdlEiIKDHJlZnJlc2hUb2tlbhgDIAEoCVIMcmVm'
        'cmVzaFRva2VuEiAKC2FjY2Vzc1Rva2VuGAQgASgJUgthY2Nlc3NUb2tlbhIaCghleGlyZXNBdB'
        'gFIAEoA1IIZXhpcmVzQXQ=');

@$core.Deprecated('Use moveToTrashRequestDescriptor instead')
const MoveToTrashRequest$json = {
  '1': 'MoveToTrashRequest',
  '2': [
    {'1': 'paths', '3': 1, '4': 3, '5': 9, '10': 'paths'},
  ],
};

/// Descriptor for `MoveToTrashRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveToTrashRequestDescriptor = $convert
    .base64Decode('ChJNb3ZlVG9UcmFzaFJlcXVlc3QSFAoFcGF0aHMYASADKAlSBXBhdGhz');

@$core.Deprecated('Use moveToTrashResponseDescriptor instead')
const MoveToTrashResponse$json = {
  '1': 'MoveToTrashResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `MoveToTrashResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveToTrashResponseDescriptor = $convert.base64Decode(
    'ChNNb3ZlVG9UcmFzaFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2'
    'FnZRgCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use trashItemDescriptor instead')
const TrashItem$json = {
  '1': 'TrashItem',
  '2': [
    {'1': 'originalPath', '3': 1, '4': 1, '5': 9, '10': 'originalPath'},
    {'1': 'trashPath', '3': 2, '4': 1, '5': 9, '10': 'trashPath'},
    {'1': 'trashedAt', '3': 3, '4': 1, '5': 3, '10': 'trashedAt'},
    {'1': 'size', '3': 4, '4': 1, '5': 3, '10': 'size'},
  ],
};

/// Descriptor for `TrashItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trashItemDescriptor = $convert.base64Decode(
    'CglUcmFzaEl0ZW0SIgoMb3JpZ2luYWxQYXRoGAEgASgJUgxvcmlnaW5hbFBhdGgSHAoJdHJhc2'
    'hQYXRoGAIgASgJUgl0cmFzaFBhdGgSHAoJdHJhc2hlZEF0GAMgASgDUgl0cmFzaGVkQXQSEgoE'
    'c2l6ZRgEIAEoA1IEc2l6ZQ==');

@$core.Deprecated('Use listTrashRequestDescriptor instead')
const ListTrashRequest$json = {
  '1': 'ListTrashRequest',
  '2': [
    {'1': 'offset', '3': 1, '4': 1, '5': 5, '10': 'offset'},
    {'1': 'maxReturn', '3': 2, '4': 1, '5': 5, '10': 'maxReturn'},
  ],
};

/// Descriptor for `ListTrashRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTrashRequestDescriptor = $convert.base64Decode(
    'ChBMaXN0VHJhc2hSZXF1ZXN0EhYKBm9mZnNldBgBIAEoBVIGb2Zmc2V0EhwKCW1heFJldHVybh'
    'gCIAEoBVIJbWF4UmV0dXJu');

@$core.Deprecated('Use listTrashResponseDescriptor instead')
const ListTrashResponse$json = {
  '1': 'ListTrashResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.img_syncer.TrashItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ListTrashResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTrashResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0VHJhc2hSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3NhZ2'
    'UYAiABKAlSB21lc3NhZ2USKwoFaXRlbXMYAyADKAsyFS5pbWdfc3luY2VyLlRyYXNoSXRlbVIF'
    'aXRlbXM=');

@$core.Deprecated('Use restoreFromTrashRequestDescriptor instead')
const RestoreFromTrashRequest$json = {
  '1': 'RestoreFromTrashRequest',
  '2': [
    {'1': 'trashPaths', '3': 1, '4': 3, '5': 9, '10': 'trashPaths'},
  ],
};

/// Descriptor for `RestoreFromTrashRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restoreFromTrashRequestDescriptor =
    $convert.base64Decode(
        'ChdSZXN0b3JlRnJvbVRyYXNoUmVxdWVzdBIeCgp0cmFzaFBhdGhzGAEgAygJUgp0cmFzaFBhdG'
        'hz');

@$core.Deprecated('Use restoreFromTrashResponseDescriptor instead')
const RestoreFromTrashResponse$json = {
  '1': 'RestoreFromTrashResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `RestoreFromTrashResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restoreFromTrashResponseDescriptor =
    $convert.base64Decode(
        'ChhSZXN0b3JlRnJvbVRyYXNoUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCg'
        'dtZXNzYWdlGAIgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use emptyTrashRequestDescriptor instead')
const EmptyTrashRequest$json = {
  '1': 'EmptyTrashRequest',
};

/// Descriptor for `EmptyTrashRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyTrashRequestDescriptor =
    $convert.base64Decode('ChFFbXB0eVRyYXNoUmVxdWVzdA==');

@$core.Deprecated('Use emptyTrashResponseDescriptor instead')
const EmptyTrashResponse$json = {
  '1': 'EmptyTrashResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `EmptyTrashResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyTrashResponseDescriptor = $convert.base64Decode(
    'ChJFbXB0eVRyYXNoUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZXNzYW'
    'dlGAIgASgJUgdtZXNzYWdl');
