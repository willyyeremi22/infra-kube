note:
- opensearch nonaktif security plugin, imbasnya
  - tidak ada sistem user-password untuk login
  - endpoint API bisa diakses langsung
- Apache Ranger memakai script custom
- dag airflow memakai gitsync dengan repo berbeda untuk tiap dag
  - pada producktion daripada membuat pod permanen untuk tiap repo dag, buat cron job dan buat job kubernetes