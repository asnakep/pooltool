### Original nixos service module to be called in configuration.nix

{ config, pkgs, ... }:

{
    systemd.services.pooltool_sendblocks = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "pooltool_sendblocks";
      serviceConfig = {
        Type = "simple";
        User = "YOUR USER";
        Group = "YOUR USER GROUP";
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = "0";
        WorkingDirectory = "/some_path/scripts/pooltool";
        RestrictNamespaces = "1";
        IPAccounting = "yes";
        IPAddressAllow = "YOUR-SERVER-IP";
        PrivateTmp = "1";
        PrivateUsers = "1";
        #ProtectHome = "yes";
        ProtectControlGroups = "1";
        ProtectKernelModules = "yes";
        ProtectKernelTunables = "yes";
        ProtectSystem = "strict";
        ProtectHostname = "1";
        ReadWritePaths = "/some_path/scripts/pooltool";
        RestrictSUIDSGID = "1";
        RestrictRealtime = "1";
        LockPersonality = "1";
        MemoryDenyWriteExecute = "1";
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = '' "~CAP_SYS_PTRACE", "~CAP_SYS_ADMIN" '';
        PrivateDevices = "1";
        NoNewPrivileges = "1";
        RemoveIPC = "yes";
        ExecStart = ''/some_path/scripts/pooltool/sendLastBlockInfo.sh'';
        ExecReload= ''/run/current-system/sw/bin/kill -1 -- $MAINPID'';
        ExecStop = ''/run/current-system/sw/bin/kill -- $MAINPID'';
        RemainAfterExit= "no";
        Restart = "always";
    };
  };
}
