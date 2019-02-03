# wireguard-scripts
helper scripts for wireguard

### requirements

- zsh
- systemd-resolve
- wireguard-tools


### client

Establish a wireguard tunnel from a client (e.g. a laptop) to a wireguard server (e.g. an openwrt box)


### endpoint or VPN server

on e.g. openwrt/lede install the wireguard packet and follow the instructions.

## Tips

### Reduce reverse MTU path size

When surfing over public networks where it's advisable to use a VPN (e.g. ÖBB or CD Train Wifi, or other mobile WIFI hotspots) you may notice that your connections suddenly dies after a short time. Websites don't load, ssh breaks, etc.

In this case, manually configure your Router (VPN Endpoint) tunnel interface MTU size to e.g. 1404.

#### Example

Asuming your tunnel interface on the endpoint side is called <tt>wgvpn</tt>:

Onetime:
<code>
ip set dev wgvpn mtu 1404
</code>

OpenWRT permament
<code>
uci set network.wgvpn.mtu=1404
uci commit
</code>

#### Explanation

The MTU size (maximum transfer unit) is how large a packet that travels over your network and through your VPN can be. Any sent packet larger than the MTU size is simply lost. The normal setting is 1500 bytes. Since our VPN uses 80 bytes overhead, WireGuard correctly sets the MTU to 1420. This tells your operating system not to send any packets larger than this.

But what if there is another VPN between you and your endpoint? That VPN takes additonal overhead. You can't really know how much or what the network infrastructure between you and your VPN endpoint really looks like. Let's say the hidden VPN takes additonal 16 bytes overhead, then all your packets between size 1405 and 1420 would have a problem. That's where ICMP comes in. Routers are supposed to tell others about fragmentation and additional MTU chokepoints, by sending an ICMP packet that basically tells your OS "Hey, your packet is too large, I'm dropping it. Don't send packets larger than xy in the future". This usually happens automatically and you don'd need to care about it.

Except way too many people use off-the-shelf firwall-products that come with broken default configurations which just block ALL ICMP traffic. Including those ICMP types that are integral to the functioning of the Internet. (e.g. Cisco is infamous for this). Most admins forget about this issue or don't know enough about networking to realize how broken these default configurations are and just leave them as they are. The result is that your largest packets just disappear. Usually on the way back to you, which is why it's usually sufficient to change the endpoints MTU size.

Thus you have to manually reduce the MTU size on your endpoint (very seldomly also on your client) to get your packets through. Since nobody will tell you, you have to guess the correct MTU. (You can try testing with <tt>tracepath</tt> but you won't have much luck if they use internet-breaking firewalls.) The 16 bytes I substracted in the example above are a good guess for most commercial mobile hotspot providers.
