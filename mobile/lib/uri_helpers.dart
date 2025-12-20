Uri joinBasePath(Uri base, String path) {
  final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
  final pathSegments = _splitPath(normalizedPath);
  final combinedSegments = <String>[
    ...base.pathSegments,
    ...pathSegments,
  ];

  return base.replace(pathSegments: combinedSegments);
}

List<String> _splitPath(String path) {
  if (path.isEmpty) {
    return const <String>[];
  }

  return path.split('/').where((segment) => segment.isNotEmpty).toList();
}
