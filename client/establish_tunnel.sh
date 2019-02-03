#!/bin/zsh
#


[[ -x =systemd-resolve ]] || { echo "ERROR: this script uses systemd-resolve which is not present"; exit 1}
[[ -x =wg ]] || { echo "ERROR: this script uses the wg utility which is not present"; exit 1}
[[ -x =ip ]] || { echo "ERROR: this script uses the ip utility which is not present"; exit 1}

. ./config.sh

[[ -r $MY_PRIV_KEY_FILE ]] || { echo "ERROR: MY_PRIV_KEY_FILE does not point to a readable file"; exit 1 }
[[ -r $OUR_PRESHARED_KEY_FILE ]] || { echo "ERROR: OUR_PRESHARED_KEY_FILE does not point to a readable file"; exit 1 }
[[ -n $REMOTE_PUB_KEY_STRING ]] || { echo "ERROR: REMOTE_PUB_KEY_STRING is empty"; exit 1 }

resolveip() {
	systemd-resolve $1 $2 | head -n1 | cut -d' ' -f2 2>/dev/null
}

local REMOTE_HOST_4=$(resolveip -4 $REMOTEHOST)
local REMOTE_HOST_6=$(resolveip -6 $REMOTEHOST)
local CUR_DEFAULT_ROUTE_4=($(ip -4 route show default | grep -v $WGIF | head -n1 | cut -d" " -f 2-))
local CUR_DEFAULT_ROUTE_6=($(ip -6 route show default | grep -v $WGIF | head -n1 | cut -d" " -f 2-))


case $1 in
(start)
	if ip link show $WGIF &>/dev/null; then
		echo "ERROR: Interface $WGIF already exists. Configure another or delete it."
		exit 1
	fi
	ip link add $WGIF type wireguard
	for net ($WGMYIPNETS) {ip addr add $net dev $WGIF}
	wg set $WGIF private-key  $MY_PRIV_KEY_FILE peer $REMOTE_PUB_KEY_STRING preshared-key $OUR_PRESHARED_KEY_FILE  allowed-ips "0.0.0.0/0,::/0" endpoint ${REMOTEHOST}:${REMOTEPORT}
	#wg set $WGIF private-key $MY_PRIV_KEY_FILE

	ip link set $WGIF up

	## add route to gw via previous default
	[[ -n $REMOTE_HOST_4 && -n $CUR_DEFAULT_ROUTE_4 ]] && ip route add $REMOTE_HOST_4 $CUR_DEFAULT_ROUTE_4 
	[[ -n $REMOTE_HOST_6 && -n $CUR_DEFAULT_ROUTE_6 ]] && ip route add $REMOTE_HOST_6 $CUR_DEFAULT_ROUTE_6 
	[[ -n $WGREMOTEGW4 ]] && ip -4 route add default via $WGREMOTEGW4 dev $WGIF metric 200
	[[ -n $WGREMOTEGW6 ]] && ip -6 route add default via $WGREMOTEGW6 dev $WGIF metric 200


;;

(stop)
	[[ -n $REMOTE_HOST_4 && -n $CUR_DEFAULT_ROUTE_4 ]] && ip route del $REMOTE_HOST_4 $CUR_DEFAULT_ROUTE_4 
	[[ -n $REMOTE_HOST_6 && -n $CUR_DEFAULT_ROUTE_6 ]] && ip route del $REMOTE_HOST_6 $CUR_DEFAULT_ROUTE_6 
	ip link set $WGIF down
	ip link del $WGIF

;;

(*)
	echo "Usage: $0 <start|stop>"
	echo
;;
esac
echo
wg show
echo
ip route show
