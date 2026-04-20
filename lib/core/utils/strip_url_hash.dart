import 'strip_url_hash_stub.dart'
    if (dart.library.html) 'strip_url_hash_web.dart' as impl;

/// Retire le fragment #access_token=… de la barre d’URL (web uniquement).
void stripAuthFragmentFromBrowserUrl() => impl.stripAuthFragmentFromBrowserUrl();
