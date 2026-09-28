# Release scope

This repository publishes the generic Espresso architecture: cost models,
standalone FPGA sources, historical resource measurements, synthetic examples,
and documentation.

Platform-specific SDKs, protocols, integration code, captures, processing
scripts, and related experimental datasets remain local. Private records, patents, reviewer
correspondence, author proofs, draft manuscripts, internal presentations,
credentials, and tool-generated files are also excluded.

The three earlier repositories were consolidated as a reviewed source snapshot.
Old Git histories were not imported into the public history because they may
contain files outside this release scope. Full Git mirror backups and original
working copies are retained locally by the repository owner.

`.gitignore` excludes local research folders. `tools/audit_release.py` checks
the Git index (including staged file contents), so force-adding an excluded file
does not bypass the release checks.

Detailed exclusion terms are kept in the owner's local-only release policy;
they are not published in repository documentation or code.
