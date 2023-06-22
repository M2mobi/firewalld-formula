# == State: firewalld.zones
#
# This state ensures that /etc/firewalld/zones/ exists.
#
{% from "firewalld/map.jinja" import firewalld with context %}

directory_firewalld_zones:
  file.directory:
    - name: /etc/firewalld/zones # make sure this is a directory
    - user: root
    - group: root
    - mode: '0750'
    - require:
      - pkg: package_firewalld # make sure package is installed
    - require_in:
      - service: service_firewalld
    - watch_in:
      - cmd: reload_firewalld # reload firewalld config

# == Define: firewalld.zones
#
# This defines a zone configuration, see firewalld.zone (5) man page.
#
{% for k, v in salt['pillar.get']('firewalld:zones', {}).items() %}
{% set z_name = v.name|default(k) %}

/etc/firewalld/zones/{{ z_name }}.xml:
  file.managed:
    - name: /etc/firewalld/zones/{{ z_name }}.xml
    - user: root
    - group: root
    - mode: '0644'
    - source: salt://firewalld/files/zone.xml
    - template: jinja
    - require:
      - pkg: package_firewalld # make sure package is installed
      - file: directory_firewalld_zones
    - require_in:
      - service: service_firewalld
    - watch_in:
      - cmd: reload_firewalld # reload firewalld config
    - context:
        name: {{ z_name }}
        zone: {{ v|json }}

clear_firewalld_{{ z_name }}_zone_dir:
  cmd.run:
    - name: "find /etc/firewalld/zones/ ! -name '{{ z_name }}.xml' -type f -exec rm -f {} +"
    - unless:
      - "grep -r 'eth0' /etc/firewalld/zones/ | wc -l | grep 1"
{% endfor %}
