## Compute Commonality

The following table outlines the methods that are available on the different compute clients. The purpose of this file is to provide guidance to users and contributors into understand where the should be cross-provider calling compatibility and where there are extended capabilities.

<table>
<tr>
<th>API</th>
<th>AWS</th>
<th>Azure</th>
<th>Joyent</th>
<th>Openstack</th>
<th>RAX</th>
<th>DigitalOcean</th>
</tr>
<tbody>
<tr><td>getVersion</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>N</td></tr>
<tr><td>createServer</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td></tr>
<tr><td>getServers</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td></tr>
<tr><td>getServer</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td></tr>
<tr><td>rebootServer</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td></tr>
<tr><td>destroyServer</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td></tr>
<tr><td>getFlavor</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td></tr>
<tr><td>getFlavors</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td></tr>
<tr><td>getImage</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td></tr>
<tr><td>getImages</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td></tr>
<tr><td colspan="6"><strong>Not Common</strong></td></tr>
<tr><td>listKeys</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>N</td><td>Y</td></tr>
<tr><td>getKey</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>N</td><td>Y</td></tr>
<tr><td>addKey</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>N</td><td>Y</td></tr>
<tr><td>destroyKey</td><td>Y</td><td>Y</td><td>Y</td><td>Y</td><td>N</td><td>Y</td></tr>
<tr><td>createImage</td><td>Y</td><td>Y</td><td>N</td><td>Y</td><td>Y</td><td>N</td></tr>
<tr><td>destroyImage</td><td>Y</td><td>Y</td><td>N</td><td>Y</td><td>Y</td><td>Y</td></tr>
<tr><td>renameServer</td><td>N</td><td>N</td><td>N</td><td>Y</td><td>Y</td><td>Y</td></tr>
<tr><td>getLimits</td><td>N</td><td>N</td><td>N</td><td>Y</td><td>Y</td><td>N</td></tr>
<tr><td>getDetails</td><td>Y</td><td>N</td><td>N</td><td>N</td><td>N</td><td>N</td></tr>
<tr><td>stopServer</td><td>N</td><td>Y</td><td>N</td><td>N</td><td>N</td><td>N</td></tr>
<tr><td>createHostedService</td><td>N</td><td>Y</td><td>N</td><td>N</td><td>N</td><td>N</td></tr>
<tr><td>resizeServer</td><td>N</td><td>N</td><td>N</td><td>Y</td><td>Y</td><td>N</td></tr>
<tr><td>rebuildServer</td><td>N</td><td>N</td><td>N</td><td>Y</td><td>Y</td><td>N</td></tr>
<tr><td>confirmServerResize</td><td>N</td><td>N</td><td>N</td><td>Y</td><td>Y</td><td>N</td></tr>
<tr><td>revertServerResize</td><td>N</td><td>N</td><td>N</td><td>Y</td><td>Y</td><td>N</td></tr>
<tr><td>getAddresses</td><td>N</td><td>N</td><td>N</td><td>Y</td><td>Y</td><td>N</td></tr>
<tr><td>addFloatingIp</td><td>N</td><td>N</td><td>N</td><td>Y</td><td>N</td><td>N</td></tr>
</tbody>
</table>

*Note: There are a few I haven't listed yet that I know exist on Rackspace/Openstack, but I lack the awareness of the other providers.*
