<?php

/* 
		Pusher PHP Library
	/////////////////////////////////
	This was a very simple PHP library to the Pusher API.

		$pusher = new Pusher(APIKEY, SECRET, APP_ID, CHANNEL, [Debug: true/false, HOST, PORT]);
		$pusher->trigger('my_event', 'test_channel', [socket_id, Debug: true/false]);
		$pusher->socket_auth('socket_id');

	Copyright 2011, Squeeks. Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php

	Contributors:
		+ Paul44 (http://github.com/Paul44)
		+ Ben Pickles (http://github.com/benpickles)
		+ Mastercoding (http://www.mastercoding.nl)
		+ Alias14 (mali0037@gmail.com)
		+ Max Williams (max@pusher.com)
		+ Zack Kitzmiller (delicious@zackisamazing.com)
		+ Andrew Bender (igothelp@gmail.com)
*/

class PusherInstance {
	
	private static $instance = null;
	private static $app_id  = '';
	private static $secret  = '';
	private static $api_key = '';
	
	private function __construct() { }
	private function __clone() { }
	
	public static function get_pusher()
	{
		if (self::$instance !== null) return self::$instance;

		self::$instance = new Pusher(
			self::$api_key, 
			self::$secret, 
			self::$app_id
		);

		return self::$instance;
	}
}

class Pusher
{

	private $settings = array ();

	/**
	* PHP5 Constructor. 
	* 
	* Initializes a new Pusher instance with key, secret , app ID and channel. 
	* You can optionally turn on debugging for all requests by setting debug to true.
	* 
	* @param string $auth_key
	* @param string $secret
	* @param int $app_id
	* @param bool $debug [optional]
	* @param string $host [optional]
	* @param int $port [optional]
	* @param int $timeout [optional]
	*/
	public function __construct( $auth_key, $secret, $app_id, $debug = false, $host = 'http://api.pusherapp.com', $port = '80', $timeout = 30 )
	{

		// Check compatibility, disable for speed improvement
		$this->check_compatibility();

		// Setup defaults
		$this->settings['server']	= $host;
		$this->settings['port']		= $port;
		$this->settings['auth_key']	= $auth_key;
		$this->settings['secret']	= $secret;
		$this->settings['app_id']	= $app_id;
		$this->settings['url']		= '/apps/' . $this->settings['app_id'];
		$this->settings['debug']	= $debug;
		$this->settings['timeout']	= $timeout;

	}

	/**
	* Check if the current PHP setup is sufficient to run this class
	*/
	private function check_compatibility()
	{

		// Check for dependent PHP extensions (JSON, cURL)
		if ( ! extension_loaded( 'curl' ) || ! extension_loaded( 'json' ) )
		{
			die( 'There is missing dependant extensions - please ensure both cURL and JSON modules are installed' );
		}

		# Supports SHA256?
		if ( ! in_array( 'sha256', hash_algos() ) )
		{
			die( 'SHA256 appears to be unsupported - make sure you have support for it, or upgrade your version of PHP.' );
		}

	}

	/**
	* Trigger an event by providing event name and payload. 
	* Optionally provide a socket ID to exclude a client (most likely the sender).
	* 
	* @param string $event
	* @param mixed $payload
	* @param int $socket_id [optional]
	* @param string $channel [optional]
	* @param bool $debug [optional]
	* @return bool|string
	*/
	public function trigger( $channel, $event, $payload, $socket_id = null, $debug = false, $already_encoded = false )
	{

		# Check if we can initialize a cURL connection
		$ch = curl_init();
		if ( $ch === false )
		{
			die( 'Could not initialise cURL!' );
		}

		# Add channel to URL..
		$s_url = $this->settings['url'] . '/channels/' . $channel . '/events';

		# Build the request
		$signature = "POST\n" . $s_url . "\n";
		$payload_encoded = $already_encoded ? $payload : json_encode( $payload );
		$query = "auth_key=" . $this->settings['auth_key'] . "&auth_timestamp=" . time() . "&auth_version=1.0&body_md5=" . md5( $payload_encoded ) . "&name=" . $event;

		# Socket ID set?
		if ( $socket_id !== null )
		{
			$query .= "&socket_id=" . $socket_id;
		}

		# Create the signed signature...
		$auth_signature = hash_hmac( 'sha256', $signature . $query, $this->settings['secret'], false );
		$signed_query = $query . "&auth_signature=" . $auth_signature;
		$full_url = $this->settings['server'] . ':' . $this->settings['port'] . $s_url . '?' . $signed_query;

		# Set cURL opts and execute request
		curl_setopt( $ch, CURLOPT_URL, $full_url );
		curl_setopt( $ch, CURLOPT_HTTPHEADER, array ( "Content-Type: application/json" ) );
		curl_setopt( $ch, CURLOPT_RETURNTRANSFER, 1 );
		curl_setopt( $ch, CURLOPT_POST, 1 );
		curl_setopt( $ch, CURLOPT_POSTFIELDS, $payload_encoded );
		curl_setopt( $ch, CURLOPT_TIMEOUT, $this->settings['timeout'] );

		$response = curl_exec( $ch );

		curl_close( $ch );

		if ( $response == "202 ACCEPTED\n" && $debug == false )
		{
			return true;
		}
		elseif ( $debug == true || $this->settings['debug'] == true )
		{
			return $response;
		}
		else
		{
			return false;
		}

	}

	/**
	* Creates a socket signature
	* 
	* @param int $socket_id
	* @param string $custom_data
	* @return string
	*/
	public function socket_auth( $channel, $socket_id, $custom_data = false )
	{

		if($custom_data == true)
		{
			$signature = hash_hmac( 'sha256', $socket_id . ':' . $channel . ':' . $custom_data, $this->settings['secret'], false );
		}
		else
		{
			$signature = hash_hmac( 'sha256', $socket_id . ':' . $channel, $this->settings['secret'], false );
		}

		$signature = array ( 'auth' => $this->settings['auth_key'] . ':' . $signature );
		// add the custom data if it has been supplied
		if($custom_data){
		  $signature['channel_data'] = $custom_data;
		}
		return json_encode( $signature );

	}

	/**
	* Creates a presence signature (an extension of socket signing)
	*
	* @param int $socket_id
	* @param string $user_id
	* @param mixed $user_info
	* @return string
	*/
	public function presence_auth( $channel, $socket_id, $user_id, $user_info = false )
	{

		$user_data = array( 'user_id' => $user_id );
		if($user_info == true)
		{
			$user_data['user_info'] = $user_info;
		}

		return $this->socket_auth($channel, $socket_id, json_encode($user_data) );
	}


}

?>
