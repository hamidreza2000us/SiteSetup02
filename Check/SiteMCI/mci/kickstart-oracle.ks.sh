<%#
kind: ptable
name: Kickstart custom
model: Ptable
oses:
- CentOS
- Fedora
- RedHat
%>

zerombr
clearpart --all --initlabel
ignoredisk --drives="/dev/disk/by-path/*fc*"

<%
 
  swap = host_param('part_swap_size') || '4096'
  root = host_param('part_root_size') || '100'
  home = host_param('part_u01_size') || '0'
  fstype = host_param('part_fstype') || 'xfs'
-%>

<% if @host.pxe_loader.include?('UEFI') -%>

  part /boot/efi --fstype="efi"  --size=200 --fsoptions="umask=0077,shortname=efi"
  <%- if (@host.operatingsystem.family == 'Redhat' && @host.operatingsystem.major.to_i >= 7 ) -%>
    part /boot --fstype="<%= fstype %>"  --size=1024
  <% else -%>
    part /boot --fstype="ext4" --size=1024
  <% end -%>
  part pv.01 --fstype="lvmpv"  --size=1024 --grow
  volgroup vg_sda --pesize=4096 pv.01
  logvol swap --fstype="swap" --size=<%= swap %> --name=lv_swap --vgname=vg_sda
  logvol / --fstype="<%= fstype %>" --size=<%= root %> --name=lv_root --vgname=vg_sda
  <% if home != '0' -%>
    logvol /u01 --fstype="<%= fstype %>" --size=<%= home %> --name=lv_u01 --vgname=vg_sda
  <% end -%>

<% elsif @host.pxe_loader.include?('BIOS') -%>

  <%- if (@host.operatingsystem.family == 'Redhat' && @host.operatingsystem.major.to_i >= 7 ) -%>
    part /boot --fstype="<%= fstype %>"  --size=1024
  <% else -%>
    part /boot --fstype="ext4"  --size=1024
  <% end -%>
  part pv.01 --fstype="lvmpv"  --size=1024 --grow
  volgroup vg_sda --pesize=4096 pv.01
  logvol swap --fstype="swap" --size=<%= swap %> --name=lv_swap --vgname=vg_sda
  logvol / --fstype="<%= fstype %>" --size=<%= root %> --name=lv_root --vgname=vg_sda
  <% if home != '0' -%>
    logvol /u01 --fstype="<%= fstype %>" --size=<%= home %> --name=lv_u01 --vgname=vg_sda
  <% end -%>

<% else -%>

# fallback to autopart, PXE loader was set to: <%= @host.pxe_loader %>
autopart <%= host_param('autopart_options') %>

<% end -%>
