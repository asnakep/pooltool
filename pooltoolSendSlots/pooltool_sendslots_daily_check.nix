{ config, pkgs, ... }:

 {

      systemd.timers.pooltool_sendslots_daily_check = {
      wantedBy = [ "timers.target" ];
      partOf = [ "pooltool_sendslots_daily_check.service" ];
      timerConfig = {
       OnCalendar = "*-*-* 23:00:00";
       };

 };

     systemd.services.pooltool_sendslots_daily_check = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "pooltool_sendslots_daily_check";
      serviceConfig = {
        Type = "simple";
        User = "root";
        Group = "root";
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = "0";
        WorkingDirectory = "/some_path/pooltool";
        RestrictNamespaces = "1";
        IPAccounting = "yes";
        IPAddressAllow = "YOUR_SERVER_IP";
        PrivateTmp = "1";
        PrivateUsers = "1";
        #ProtectHome = "yes";
        ProtectControlGroups = "1";
        ProtectKernelModules = "yes";
        ProtectKernelTunables = "yes";
        ProtectSystem = "strict";
        ProtectHostname = "1";
        ReadWritePaths = "/some_path/pooltool /var/lib/prometheus-node-exporter-text-files";
        RestrictSUIDSGID = "1";
        RestrictRealtime = "1";
        LockPersonality = "1";
        MemoryDenyWriteExecute = "1";
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = '' "~CAP_SYS_PTRACE", "~CAP_SYS_ADMIN" '';
        PrivateDevices = "1";
        NoNewPrivileges = "1";
        RemoveIPC = "yes";
        Environment = "NIX_PATH=/nix/var/nix/profiles/per-user/root/channels/nixos";
        ExecStart = ''/some_path/getAndSendSlots2Pooltool.sh'';
        RemainAfterExit= "no";
        Restart = "no";
    };
  };
}
