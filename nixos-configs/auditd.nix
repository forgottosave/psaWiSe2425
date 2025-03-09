{ config, lib, pkgs, ... }:
{
  services.auditd = {
    enable = true;
    
    # Log management settings
    settings = {
      log_file = "/var/log/audit/audit.log"; 
      log_format = "ENRICHED";                     # Detailed logs for better analysis
      max_log_file = 50;                           # Max log file size in MB  
      max_log_file_action = "ROTATE";              # Rotate logs when full
      num_logs = 5;                                # Keep last 5 log files 
      flush = "INCREMENTAL_ASYNC";
    };

    rules = [
      # ==== File Integrity Monitoring ====
      # Monitor critical system files for changes
      "-w /etc/passwd -p wa -k passwd_changes"  
      "-w /etc/shadow -p wa -k shadow_changes"
      "-w /etc/ssh/sshd_config -p wa -k sshd_config_changes"

      # ==== User Activity Monitoring ====
      # Track execution of privileged commands
      "-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged_sudo"
      "-a always,exit -F path=/bin/su -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged_su" 
      # Monitor user logins and authentication
      "-w /var/log/auth.log -p rwxa -k auth_logs"

      # ==== System Call Monitoring ====
      # Detect suspicious use of chmod, chown, and mount
      "-a always,exit -F arch=b64 -S chmod -S chown -S mount -k suspicious_changes"  
      "-a always,exit -F arch=b32 -S chmod -S chown -S mount -k suspicious_changes" 
      # Monitor file deletions by users
      "-a always,exit -F arch=b64 -S unlink -S rename -F auid>=1000 -F auid!=4294967295 -k file_deletion"
      "-a always,exit -F arch=b32 -S unlink -S rename -F auid>=1000 -F auid!=4294967295 -k file_deletion"

      # ==== Security Configuration Monitoring ====
      # Monitor changes to audit configuration
      "-w /etc/audit/ -p wa -k audit_config_changes"

      # ==== Nix-Specific Optimization ====
      # Exclude Nix store paths to reduce noise
      "-a never,exit -F dir=/nix/store -k nix_store"
    ];
  };
}
