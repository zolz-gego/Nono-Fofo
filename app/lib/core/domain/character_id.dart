/// The two brothers. `name` matches the folder/key used in asset manifests.
enum CharacterId {
  nono,
  fofo;

  CharacterId get other => this == nono ? fofo : nono;
}
