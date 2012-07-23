<?php
class Executor{
	
	public function run($query){
	
    $request  = json_decode($query['data'],true);
    $username = $request['username'];
    $command  = $request["withArgs"]["command"];
    
    $tmpfile = "/tmp/".microtime(true).".sh";
    file_put_contents($tmpfile,$command);
    
    $cmd = "/usr/bin/sudo /bin/su -l {$username} -c 'sh {$tmpfile}'";
    $p = $this->systemProcess($cmd);
        
    $this->respondWith(array("result"=>$p),$query);
    
	}
				
	public function systemProcess($cmd){
	
		$p = new pbsSystemProcess($cmd); 
		$p->nonZeroExitCodeException = true;
		$returnCode = $p->execute(false);
		return array("stderr"=>$p->stderrOutput,"stdout"=>$p->stdoutOutput);
	}
		
  public function respondWith($res,$query){
      echo  $query['callback']."(" . json_encode($res) . ")";
  }
	

}
