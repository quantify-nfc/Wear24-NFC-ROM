#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/platform/soc/7824900.sdhci/by-name/recovery:12346668:05f3db23270c2b4b5886a62376983cb2ae0fc6f0; then
  applypatch -b /system/etc/recovery-resource.dat EMMC:/dev/block/platform/soc/7824900.sdhci/by-name/boot:10032424:9f9428c7dc948e78995b81162d3e77565056a665 EMMC:/dev/block/platform/soc/7824900.sdhci/by-name/recovery 05f3db23270c2b4b5886a62376983cb2ae0fc6f0 12346668 9f9428c7dc948e78995b81162d3e77565056a665:/system/recovery-from-boot.p && log -t recovery "Installing new recovery image: succeeded" || log -t recovery "Installing new recovery image: failed"
else
  log -t recovery "Recovery image already installed"
fi
