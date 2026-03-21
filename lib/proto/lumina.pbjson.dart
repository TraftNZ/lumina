// This is a generated file - do not edit.
//
// Generated from proto/lumina.proto.

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
    {'1': 'content_hash', '3': 4, '4': 1, '5': 9, '10': 'contentHash'},
  ],
};

/// Descriptor for `FilterNotUploadedRequestInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filterNotUploadedRequestInfoDescriptor =
    $convert.base64Decode(
        'ChxGaWx0ZXJOb3RVcGxvYWRlZFJlcXVlc3RJbmZvEhIKBG5hbWUYASABKAlSBG5hbWUSEgoEZG'
        'F0ZRgCIAEoCVIEZGF0ZRIOCgJpZBgDIAEoCVICaWQSIQoMY29udGVudF9oYXNoGAQgASgJUgtj'
        'b250ZW50SGFzaA==');

@$core.Deprecated('Use filterNotUploadedRequestDescriptor instead')
const FilterNotUploadedRequest$json = {
  '1': 'FilterNotUploadedRequest',
  '2': [
    {
      '1': 'photos',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.lumina.FilterNotUploadedRequestInfo',
      '10': 'photos'
    },
    {'1': 'isFinished', '3': 2, '4': 1, '5': 8, '10': 'isFinished'},
  ],
};

/// Descriptor for `FilterNotUploadedRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filterNotUploadedRequestDescriptor = $convert.base64Decode(
    'ChhGaWx0ZXJOb3RVcGxvYWRlZFJlcXVlc3QSPAoGcGhvdG9zGAEgAygLMiQubHVtaW5hLkZpbH'
    'Rlck5vdFVwbG9hZGVkUmVxdWVzdEluZm9SBnBob3RvcxIeCgppc0ZpbmlzaGVkGAIgASgIUgpp'
    'c0ZpbmlzaGVk');

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

@$core.Deprecated('Use setDriveS3RequestDescriptor instead')
const SetDriveS3Request$json = {
  '1': 'SetDriveS3Request',
  '2': [
    {'1': 'endpoint', '3': 1, '4': 1, '5': 9, '10': 'endpoint'},
    {'1': 'region', '3': 2, '4': 1, '5': 9, '10': 'region'},
    {'1': 'accessKeyId', '3': 3, '4': 1, '5': 9, '10': 'accessKeyId'},
    {'1': 'secretAccessKey', '3': 4, '4': 1, '5': 9, '10': 'secretAccessKey'},
    {'1': 'bucket', '3': 5, '4': 1, '5': 9, '10': 'bucket'},
    {'1': 'root', '3': 6, '4': 1, '5': 9, '10': 'root'},
  ],
};

/// Descriptor for `SetDriveS3Request`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveS3RequestDescriptor = $convert.base64Decode(
    'ChFTZXREcml2ZVMzUmVxdWVzdBIaCghlbmRwb2ludBgBIAEoCVIIZW5kcG9pbnQSFgoGcmVnaW'
    '9uGAIgASgJUgZyZWdpb24SIAoLYWNjZXNzS2V5SWQYAyABKAlSC2FjY2Vzc0tleUlkEigKD3Nl'
    'Y3JldEFjY2Vzc0tleRgEIAEoCVIPc2VjcmV0QWNjZXNzS2V5EhYKBmJ1Y2tldBgFIAEoCVIGYn'
    'Vja2V0EhIKBHJvb3QYBiABKAlSBHJvb3Q=');

@$core.Deprecated('Use setDriveS3ResponseDescriptor instead')
const SetDriveS3Response$json = {
  '1': 'SetDriveS3Response',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `SetDriveS3Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveS3ResponseDescriptor = $convert.base64Decode(
    'ChJTZXREcml2ZVMzUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZXNzYW'
    'dlGAIgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use listDriveS3BucketsRequestDescriptor instead')
const ListDriveS3BucketsRequest$json = {
  '1': 'ListDriveS3BucketsRequest',
};

/// Descriptor for `ListDriveS3BucketsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveS3BucketsRequestDescriptor =
    $convert.base64Decode('ChlMaXN0RHJpdmVTM0J1Y2tldHNSZXF1ZXN0');

@$core.Deprecated('Use listDriveS3BucketsResponseDescriptor instead')
const ListDriveS3BucketsResponse$json = {
  '1': 'ListDriveS3BucketsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'buckets', '3': 3, '4': 3, '5': 9, '10': 'buckets'},
  ],
};

/// Descriptor for `ListDriveS3BucketsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveS3BucketsResponseDescriptor =
    $convert.base64Decode(
        'ChpMaXN0RHJpdmVTM0J1Y2tldHNSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEh'
        'gKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2USGAoHYnVja2V0cxgDIAMoCVIHYnVja2V0cw==');

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
      '6': '.lumina.TrashItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ListTrashResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTrashResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0VHJhc2hSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3NhZ2'
    'UYAiABKAlSB21lc3NhZ2USJwoFaXRlbXMYAyADKAsyES5sdW1pbmEuVHJhc2hJdGVtUgVpdGVt'
    'cw==');

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

@$core.Deprecated('Use moveToLockedRequestDescriptor instead')
const MoveToLockedRequest$json = {
  '1': 'MoveToLockedRequest',
  '2': [
    {'1': 'paths', '3': 1, '4': 3, '5': 9, '10': 'paths'},
  ],
};

/// Descriptor for `MoveToLockedRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveToLockedRequestDescriptor =
    $convert.base64Decode(
        'ChNNb3ZlVG9Mb2NrZWRSZXF1ZXN0EhQKBXBhdGhzGAEgAygJUgVwYXRocw==');

@$core.Deprecated('Use moveToLockedResponseDescriptor instead')
const MoveToLockedResponse$json = {
  '1': 'MoveToLockedResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `MoveToLockedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveToLockedResponseDescriptor = $convert.base64Decode(
    'ChRNb3ZlVG9Mb2NrZWRSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3'
    'NhZ2UYAiABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use restoreFromLockedRequestDescriptor instead')
const RestoreFromLockedRequest$json = {
  '1': 'RestoreFromLockedRequest',
  '2': [
    {'1': 'lockedPaths', '3': 1, '4': 3, '5': 9, '10': 'lockedPaths'},
  ],
};

/// Descriptor for `RestoreFromLockedRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restoreFromLockedRequestDescriptor =
    $convert.base64Decode(
        'ChhSZXN0b3JlRnJvbUxvY2tlZFJlcXVlc3QSIAoLbG9ja2VkUGF0aHMYASADKAlSC2xvY2tlZF'
        'BhdGhz');

@$core.Deprecated('Use restoreFromLockedResponseDescriptor instead')
const RestoreFromLockedResponse$json = {
  '1': 'RestoreFromLockedResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `RestoreFromLockedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restoreFromLockedResponseDescriptor =
    $convert.base64Decode(
        'ChlSZXN0b3JlRnJvbUxvY2tlZFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGA'
        'oHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use listLockedRequestDescriptor instead')
const ListLockedRequest$json = {
  '1': 'ListLockedRequest',
  '2': [
    {'1': 'offset', '3': 1, '4': 1, '5': 5, '10': 'offset'},
    {'1': 'maxReturn', '3': 2, '4': 1, '5': 5, '10': 'maxReturn'},
  ],
};

/// Descriptor for `ListLockedRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listLockedRequestDescriptor = $convert.base64Decode(
    'ChFMaXN0TG9ja2VkUmVxdWVzdBIWCgZvZmZzZXQYASABKAVSBm9mZnNldBIcCgltYXhSZXR1cm'
    '4YAiABKAVSCW1heFJldHVybg==');

@$core.Deprecated('Use listLockedResponseDescriptor instead')
const ListLockedResponse$json = {
  '1': 'ListLockedResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.lumina.TrashItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ListLockedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listLockedResponseDescriptor = $convert.base64Decode(
    'ChJMaXN0TG9ja2VkUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZXNzYW'
    'dlGAIgASgJUgdtZXNzYWdlEicKBWl0ZW1zGAMgAygLMhEubHVtaW5hLlRyYXNoSXRlbVIFaXRl'
    'bXM=');

@$core.Deprecated('Use updatePhotoLabelsRequestDescriptor instead')
const UpdatePhotoLabelsRequest$json = {
  '1': 'UpdatePhotoLabelsRequest',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'labels', '3': 2, '4': 3, '5': 9, '10': 'labels'},
    {'1': 'faceIDs', '3': 3, '4': 3, '5': 9, '10': 'faceIDs'},
    {'1': 'text', '3': 4, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `UpdatePhotoLabelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePhotoLabelsRequestDescriptor = $convert.base64Decode(
    'ChhVcGRhdGVQaG90b0xhYmVsc1JlcXVlc3QSEgoEcGF0aBgBIAEoCVIEcGF0aBIWCgZsYWJlbH'
    'MYAiADKAlSBmxhYmVscxIYCgdmYWNlSURzGAMgAygJUgdmYWNlSURzEhIKBHRleHQYBCABKAlS'
    'BHRleHQ=');

@$core.Deprecated('Use updatePhotoLabelsResponseDescriptor instead')
const UpdatePhotoLabelsResponse$json = {
  '1': 'UpdatePhotoLabelsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `UpdatePhotoLabelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePhotoLabelsResponseDescriptor =
    $convert.base64Decode(
        'ChlVcGRhdGVQaG90b0xhYmVsc1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGA'
        'oHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use searchPhotosRequestDescriptor instead')
const SearchPhotosRequest$json = {
  '1': 'SearchPhotosRequest',
  '2': [
    {'1': 'query', '3': 1, '4': 1, '5': 9, '10': 'query'},
  ],
};

/// Descriptor for `SearchPhotosRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchPhotosRequestDescriptor =
    $convert.base64Decode(
        'ChNTZWFyY2hQaG90b3NSZXF1ZXN0EhQKBXF1ZXJ5GAEgASgJUgVxdWVyeQ==');

@$core.Deprecated('Use searchPhotosResponseDescriptor instead')
const SearchPhotosResponse$json = {
  '1': 'SearchPhotosResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'paths', '3': 3, '4': 3, '5': 9, '10': 'paths'},
  ],
};

/// Descriptor for `SearchPhotosResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchPhotosResponseDescriptor = $convert.base64Decode(
    'ChRTZWFyY2hQaG90b3NSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3'
    'NhZ2UYAiABKAlSB21lc3NhZ2USFAoFcGF0aHMYAyADKAlSBXBhdGhz');

@$core.Deprecated('Use getUnlabeledPhotosRequestDescriptor instead')
const GetUnlabeledPhotosRequest$json = {
  '1': 'GetUnlabeledPhotosRequest',
  '2': [
    {'1': 'limit', '3': 1, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `GetUnlabeledPhotosRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUnlabeledPhotosRequestDescriptor =
    $convert.base64Decode(
        'ChlHZXRVbmxhYmVsZWRQaG90b3NSZXF1ZXN0EhQKBWxpbWl0GAEgASgFUgVsaW1pdA==');

@$core.Deprecated('Use getUnlabeledPhotosResponseDescriptor instead')
const GetUnlabeledPhotosResponse$json = {
  '1': 'GetUnlabeledPhotosResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'paths', '3': 3, '4': 3, '5': 9, '10': 'paths'},
  ],
};

/// Descriptor for `GetUnlabeledPhotosResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUnlabeledPhotosResponseDescriptor =
    $convert.base64Decode(
        'ChpHZXRVbmxhYmVsZWRQaG90b3NSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEh'
        'gKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2USFAoFcGF0aHMYAyADKAlSBXBhdGhz');

@$core.Deprecated('Use getLabelSummaryRequestDescriptor instead')
const GetLabelSummaryRequest$json = {
  '1': 'GetLabelSummaryRequest',
};

/// Descriptor for `GetLabelSummaryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLabelSummaryRequestDescriptor =
    $convert.base64Decode('ChZHZXRMYWJlbFN1bW1hcnlSZXF1ZXN0');

@$core.Deprecated('Use labelSummaryItemDescriptor instead')
const LabelSummaryItem$json = {
  '1': 'LabelSummaryItem',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
    {'1': 'samplePath', '3': 3, '4': 1, '5': 9, '10': 'samplePath'},
  ],
};

/// Descriptor for `LabelSummaryItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List labelSummaryItemDescriptor = $convert.base64Decode(
    'ChBMYWJlbFN1bW1hcnlJdGVtEhQKBWxhYmVsGAEgASgJUgVsYWJlbBIUCgVjb3VudBgCIAEoBV'
    'IFY291bnQSHgoKc2FtcGxlUGF0aBgDIAEoCVIKc2FtcGxlUGF0aA==');

@$core.Deprecated('Use getLabelSummaryResponseDescriptor instead')
const GetLabelSummaryResponse$json = {
  '1': 'GetLabelSummaryResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'labels',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.lumina.LabelSummaryItem',
      '10': 'labels'
    },
    {'1': 'faceCount', '3': 3, '4': 1, '5': 5, '10': 'faceCount'},
    {'1': 'faceSamplePath', '3': 4, '4': 1, '5': 9, '10': 'faceSamplePath'},
  ],
};

/// Descriptor for `GetLabelSummaryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLabelSummaryResponseDescriptor = $convert.base64Decode(
    'ChdHZXRMYWJlbFN1bW1hcnlSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEjAKBm'
    'xhYmVscxgCIAMoCzIYLmx1bWluYS5MYWJlbFN1bW1hcnlJdGVtUgZsYWJlbHMSHAoJZmFjZUNv'
    'dW50GAMgASgFUglmYWNlQ291bnQSJgoOZmFjZVNhbXBsZVBhdGgYBCABKAlSDmZhY2VTYW1wbG'
    'VQYXRo');

@$core.Deprecated('Use syncIndexRequestDescriptor instead')
const SyncIndexRequest$json = {
  '1': 'SyncIndexRequest',
};

/// Descriptor for `SyncIndexRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncIndexRequestDescriptor =
    $convert.base64Decode('ChBTeW5jSW5kZXhSZXF1ZXN0');

@$core.Deprecated('Use syncIndexResponseDescriptor instead')
const SyncIndexResponse$json = {
  '1': 'SyncIndexResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'totalFiles', '3': 3, '4': 1, '5': 5, '10': 'totalFiles'},
  ],
};

/// Descriptor for `SyncIndexResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncIndexResponseDescriptor = $convert.base64Decode(
    'ChFTeW5jSW5kZXhSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3NhZ2'
    'UYAiABKAlSB21lc3NhZ2USHgoKdG90YWxGaWxlcxgDIAEoBVIKdG90YWxGaWxlcw==');

@$core.Deprecated('Use fullResyncIndexRequestDescriptor instead')
const FullResyncIndexRequest$json = {
  '1': 'FullResyncIndexRequest',
};

/// Descriptor for `FullResyncIndexRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullResyncIndexRequestDescriptor =
    $convert.base64Decode('ChZGdWxsUmVzeW5jSW5kZXhSZXF1ZXN0');

@$core.Deprecated('Use fullResyncIndexResponseDescriptor instead')
const FullResyncIndexResponse$json = {
  '1': 'FullResyncIndexResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'totalFiles', '3': 3, '4': 1, '5': 5, '10': 'totalFiles'},
  ],
};

/// Descriptor for `FullResyncIndexResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullResyncIndexResponseDescriptor = $convert.base64Decode(
    'ChdGdWxsUmVzeW5jSW5kZXhSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB2'
    '1lc3NhZ2UYAiABKAlSB21lc3NhZ2USHgoKdG90YWxGaWxlcxgDIAEoBVIKdG90YWxGaWxlcw==');

@$core.Deprecated('Use setDriveCloudrveRequestDescriptor instead')
const SetDriveCloudrveRequest$json = {
  '1': 'SetDriveCloudrveRequest',
  '2': [
    {'1': 'server', '3': 1, '4': 1, '5': 9, '10': 'server'},
    {'1': 'email', '3': 2, '4': 1, '5': 9, '10': 'email'},
    {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
    {'1': 'root', '3': 4, '4': 1, '5': 9, '10': 'root'},
    {'1': 'otp', '3': 5, '4': 1, '5': 9, '10': 'otp'},
    {'1': 'session_id', '3': 6, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `SetDriveCloudrveRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveCloudrveRequestDescriptor = $convert.base64Decode(
    'ChdTZXREcml2ZUNsb3VkcnZlUmVxdWVzdBIWCgZzZXJ2ZXIYASABKAlSBnNlcnZlchIUCgVlbW'
    'FpbBgCIAEoCVIFZW1haWwSGgoIcGFzc3dvcmQYAyABKAlSCHBhc3N3b3JkEhIKBHJvb3QYBCAB'
    'KAlSBHJvb3QSEAoDb3RwGAUgASgJUgNvdHASHQoKc2Vzc2lvbl9pZBgGIAEoCVIJc2Vzc2lvbk'
    'lk');

@$core.Deprecated('Use setDriveCloudrveResponseDescriptor instead')
const SetDriveCloudrveResponse$json = {
  '1': 'SetDriveCloudrveResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'require_2fa', '3': 3, '4': 1, '5': 8, '10': 'require2fa'},
    {'1': 'session_id', '3': 4, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `SetDriveCloudrveResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDriveCloudrveResponseDescriptor = $convert.base64Decode(
    'ChhTZXREcml2ZUNsb3VkcnZlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCg'
    'dtZXNzYWdlGAIgASgJUgdtZXNzYWdlEh8KC3JlcXVpcmVfMmZhGAMgASgIUgpyZXF1aXJlMmZh'
    'Eh0KCnNlc3Npb25faWQYBCABKAlSCXNlc3Npb25JZA==');

@$core.Deprecated('Use listDriveClourdreveDirRequestDescriptor instead')
const ListDriveClourdreveDirRequest$json = {
  '1': 'ListDriveClourdreveDirRequest',
  '2': [
    {'1': 'dir', '3': 1, '4': 1, '5': 9, '10': 'dir'},
  ],
};

/// Descriptor for `ListDriveClourdreveDirRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveClourdreveDirRequestDescriptor =
    $convert.base64Decode(
        'Ch1MaXN0RHJpdmVDbG91cmRyZXZlRGlyUmVxdWVzdBIQCgNkaXIYASABKAlSA2Rpcg==');

@$core.Deprecated('Use listDriveClourdreveDirResponseDescriptor instead')
const ListDriveClourdreveDirResponse$json = {
  '1': 'ListDriveClourdreveDirResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'dirs', '3': 3, '4': 3, '5': 9, '10': 'dirs'},
  ],
};

/// Descriptor for `ListDriveClourdreveDirResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDriveClourdreveDirResponseDescriptor =
    $convert.base64Decode(
        'Ch5MaXN0RHJpdmVDbG91cmRyZXZlRGlyUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2'
        'VzcxIYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdlEhIKBGRpcnMYAyADKAlSBGRpcnM=');

@$core.Deprecated('Use getYearSummaryRequestDescriptor instead')
const GetYearSummaryRequest$json = {
  '1': 'GetYearSummaryRequest',
};

/// Descriptor for `GetYearSummaryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getYearSummaryRequestDescriptor =
    $convert.base64Decode('ChVHZXRZZWFyU3VtbWFyeVJlcXVlc3Q=');

@$core.Deprecated('Use yearSummaryItemDescriptor instead')
const YearSummaryItem$json = {
  '1': 'YearSummaryItem',
  '2': [
    {'1': 'year', '3': 1, '4': 1, '5': 5, '10': 'year'},
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
    {'1': 'samplePath', '3': 3, '4': 1, '5': 9, '10': 'samplePath'},
  ],
};

/// Descriptor for `YearSummaryItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List yearSummaryItemDescriptor = $convert.base64Decode(
    'Cg9ZZWFyU3VtbWFyeUl0ZW0SEgoEeWVhchgBIAEoBVIEeWVhchIUCgVjb3VudBgCIAEoBVIFY2'
    '91bnQSHgoKc2FtcGxlUGF0aBgDIAEoCVIKc2FtcGxlUGF0aA==');

@$core.Deprecated('Use getYearSummaryResponseDescriptor instead')
const GetYearSummaryResponse$json = {
  '1': 'GetYearSummaryResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'years',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.lumina.YearSummaryItem',
      '10': 'years'
    },
  ],
};

/// Descriptor for `GetYearSummaryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getYearSummaryResponseDescriptor =
    $convert.base64Decode(
        'ChZHZXRZZWFyU3VtbWFyeVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSLQoFeW'
        'VhcnMYAiADKAsyFy5sdW1pbmEuWWVhclN1bW1hcnlJdGVtUgV5ZWFycw==');

@$core.Deprecated('Use getPhotosByYearRequestDescriptor instead')
const GetPhotosByYearRequest$json = {
  '1': 'GetPhotosByYearRequest',
  '2': [
    {'1': 'year', '3': 1, '4': 1, '5': 5, '10': 'year'},
    {'1': 'offset', '3': 2, '4': 1, '5': 5, '10': 'offset'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `GetPhotosByYearRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPhotosByYearRequestDescriptor =
    $convert.base64Decode(
        'ChZHZXRQaG90b3NCeVllYXJSZXF1ZXN0EhIKBHllYXIYASABKAVSBHllYXISFgoGb2Zmc2V0GA'
        'IgASgFUgZvZmZzZXQSFAoFbGltaXQYAyABKAVSBWxpbWl0');

@$core.Deprecated('Use getPhotosByYearResponseDescriptor instead')
const GetPhotosByYearResponse$json = {
  '1': 'GetPhotosByYearResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'paths', '3': 2, '4': 3, '5': 9, '10': 'paths'},
    {'1': 'total', '3': 3, '4': 1, '5': 5, '10': 'total'},
  ],
};

/// Descriptor for `GetPhotosByYearResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPhotosByYearResponseDescriptor =
    $convert.base64Decode(
        'ChdHZXRQaG90b3NCeVllYXJSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhQKBX'
        'BhdGhzGAIgAygJUgVwYXRocxIUCgV0b3RhbBgDIAEoBVIFdG90YWw=');

@$core.Deprecated('Use getCloudLocationsRequestDescriptor instead')
const GetCloudLocationsRequest$json = {
  '1': 'GetCloudLocationsRequest',
};

/// Descriptor for `GetCloudLocationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCloudLocationsRequestDescriptor =
    $convert.base64Decode('ChhHZXRDbG91ZExvY2F0aW9uc1JlcXVlc3Q=');

@$core.Deprecated('Use cloudLocationItemDescriptor instead')
const CloudLocationItem$json = {
  '1': 'CloudLocationItem',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'latitude', '3': 2, '4': 1, '5': 1, '10': 'latitude'},
    {'1': 'longitude', '3': 3, '4': 1, '5': 1, '10': 'longitude'},
  ],
};

/// Descriptor for `CloudLocationItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cloudLocationItemDescriptor = $convert.base64Decode(
    'ChFDbG91ZExvY2F0aW9uSXRlbRISCgRwYXRoGAEgASgJUgRwYXRoEhoKCGxhdGl0dWRlGAIgAS'
    'gBUghsYXRpdHVkZRIcCglsb25naXR1ZGUYAyABKAFSCWxvbmdpdHVkZQ==');

@$core.Deprecated('Use getCloudLocationsResponseDescriptor instead')
const GetCloudLocationsResponse$json = {
  '1': 'GetCloudLocationsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'locations',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.lumina.CloudLocationItem',
      '10': 'locations'
    },
  ],
};

/// Descriptor for `GetCloudLocationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCloudLocationsResponseDescriptor = $convert.base64Decode(
    'ChlHZXRDbG91ZExvY2F0aW9uc1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSNw'
    'oJbG9jYXRpb25zGAIgAygLMhkubHVtaW5hLkNsb3VkTG9jYXRpb25JdGVtUglsb2NhdGlvbnM=');
