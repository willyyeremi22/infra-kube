note:
- opensearch nonaktif security plugin, imbasnya
  - tidak ada sistem user-password untuk login
  - endpoint API bisa diakses langsung
- LDAP pakai LLDAP, imbasnya
  - sistem OU tidak ada
  - data disimpan di postgres
  - Apache Ranger tidak bisa query langsung, class LdapUserGroupBuilder selalu menambahkan klausa (|(uSNChanged>=X)(modifyTimestamp>=Y)), lldap tidak mengimplementasikan operator perbandingan ini sama sekali, server langsung menolak dengan LDAP error code 53 (unwillingToPerform)