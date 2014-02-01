#!/usr/bin/perl
#-------------------------------------------------------------------------
#  Copyright 2007, NETGEAR
#  All rights reserved.
#-------------------------------------------------------------------------

do "/frontview/lib/cgi-lib.pl";
do "/frontview/lib/addon.pl";

# initialize the %in hash
%in = ();
ReadParse();

my $operation      = $in{OPERATION};
my $command        = $in{command};
my $enabled        = $in{"CHECKBOX_AUTONFS_ENABLED"};
my $data           = $in{"data"};

get_default_language_strings("AUTONFS");
 
my $xml_payload = "Content-type: text/xml; charset=utf-8\n\n"."<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
 
if( $operation eq "get" )
{
  $xml_payload .= Show_AUTONFS_xml();
}
elsif( $operation eq "set" )
{
  if( $command eq "RemoveAddOn" )
  {
    # Remove_Service_xml() removes this add-on
    $xml_payload .= Remove_Service_xml("AUTONFS", $data);
  }
  elsif ($command eq "ToggleService")
  {
    # Toggle_Service_xml() toggles the enabled state of the add-on
    $xml_payload .= Toggle_Service_xml("AUTONFS", $enabled);
  }
  elsif ($command eq "ModifyAddOnService")
  {
    # Modify_AUTONFS_xml() processes the input form changes
    $xml_payload .= Modify_AUTONFS_xml();
  }
}

print $xml_payload;
  
##################################################################
#                                                                 
#                                                                 
#                                                                 
##################################################################
sub localGetValueFromServiceFile                                       
{                                                                 
  my $input_key = shift;                                          
  my $ret_val = "NOT_FOUND";                                      
                                                                  
  foreach my $line ( @{ read_file( "/etc/default/services" ) } )  
  {                                                               
    chomp ($line);                                                
    my ($key, $val) = $line =~ /([^=]+)=(.*)/;
                                                                   
    if ( $key eq $input_key )                                      
    {                                                              
       $ret_val = $val;                                            
       last;                                                       
    }                                                              
  }                                                                
  return $ret_val;                                                 
} 

sub Show_AUTONFS_xml
{
  my $xml_payload = "<payload><content>" ;

  # check if service is running or not 
  my $enabled = GetServiceStatus("AUTONFS");

  my $fileserver = GetValueFromServiceFile("AUTONFS_FILESERVER");

  if( $fileserver eq "NOT_FOUND" || $fileserver eq "")                                 
  {                                                              
    # set run_time to a default value                            
    $fileserver = "yournfsserverhere";                                            
  }  

  my $mountopts = localGetValueFromServiceFile("AUTONFS_MOUNTOPTS");                                                           
                                                                                                                            
  if( $mountopts eq "NOT_FOUND" || $mountopts eq "")                                                                      
  {                                                                                                                         
    # set mountopts to a default value                                                                                       
    $mountopts = "-o%20rw,hard,intr,tcp,actimeo=3";                                                                                      
  }

  my $mounts = localGetValueFromServiceFile("AUTONFS_MOUNTS");
                                                                    
  if( $mounts eq "NOT_FOUND" || $mounts eq "")                
  {                                                                 
    # set mounts to a default value                              
    $mounts = '%20"/media/exampleRemote1|/media/exampleLocal1"%20"/media/exampleMount2"%20';                 
  } 

  my $interval = GetValueFromServiceFile("AUTONFS_INTERVAL");  
                                                                   
  if( $interval eq "NOT_FOUND" || $interval == "")                                   
  {                                                                
    # set interval to a default value                              
    $interval = "60";                                              
  }

  my $enabled_disabled = "disabled";
     $enabled_disabled = "enabled" if( $enabled );

  # return run_time value for HTML
  $xml_payload .= "<AUTONFS_FILESERVER><value>$fileserver</value><enable>$enabled_disabled</enable></AUTONFS_FILESERVER>";
  $xml_payload .= "<AUTONFS_MOUNTOPTS><value>$mountopts</value><enable>$enabled_disabled</enable></AUTONFS_MOUNTOPTS>";
  $xml_payload .= "<AUTONFS_MOUNTS><value>$mounts</value><enable>$enabled_disabled</enable></AUTONFS_MOUNTS>";
  $xml_payload .= "<AUTONFS_INTERVAL><value>$interval</value><enable>$enabled_disabled</enable></AUTONFS_INTERVAL>";

  $xml_payload .= "</content><warning>No Warnings</warning><error>No Errors</error></payload>";
  
  return $xml_payload;
}


sub Modify_AUTONFS_xml 
{
  my $fileserver  = $in{"AUTONFS_FILESERVER"};
  my $mountopts  = $in{"AUTONFS_MOUNTOPTS"};
  my $mounts  = $in{"AUTONFS_MOUNTS"};
  my $interval  = $in{"AUTONFS_INTERVAL"};

  my $SPOOL;
  my $xml_payload;
  
  $fileserver = "yournfsserverhere" if( $fileserver eq "" );
  $mountopts = "-o rw,hard,intr,tcp,actimeo=3" if ( $mountopts eq "" );
  $mounts = ' "/media/exampleRemote1|/media/exampleLocal1" "/media/exampleMount2" ' if ( $mounts eq "" );
  $interval = "60" if( $interval eq "" );

  $mountopts =~ s/ /%20/g;
  $mounts =~ s/ /%20/g;

  if ($fileserver ne GetValueFromServiceFile("AUTONFS_FILESERVER") || $mountopts ne localGetValueFromServiceFile("AUTONFS_MOUNTOPTS") || $mounts ne localGetValueFromServiceFile("AUTONFS_MOUNTS")) {
    $SPOOL .= "
sh /etc/frontview/addons/bin/AUTONFS/stop.sh UNMOUNT
";
  }
  else {
    $SPOOL .= "
sh /etc/frontview/addons/bin/AUTONFS/stop.sh
";
  }

  $SPOOL .= "                                                                                                               
if grep -q AUTONFS_FILESERVER /etc/default/services; then                                                                 
  sed -i 's/AUTONFS_FILESERVER=.*/AUTONFS_FILESERVER=${fileserver}/' /etc/default/services                                
else                                                                                                                        
  echo 'AUTONFS_FILESERVER=${fileserver}' >> /etc/default/services                                                          
fi                                                                                                                          
";

 $mounts =~ s/\//\\\//g;

  $SPOOL .= "                                                                                                               
if grep -q AUTONFS_MOUNTOPTS /etc/default/services; then                                                                   
  sed -i 's/AUTONFS_MOUNTOPTS=.*/AUTONFS_MOUNTOPTS=${mountopts}/' /etc/default/services                                  
else                                                                                                                        
  echo 'AUTONFS_MOUNTOPTS=${mountopts}' >> /etc/default/services                                                          
fi                                                                                                                          
";
 
  $SPOOL .= "                                                                                                               
if grep -q AUTONFS_MOUNTS /etc/default/services; then                                                                  
  sed -i 's/AUTONFS_MOUNTS=.*/AUTONFS_MOUNTS=${mounts}/' /etc/default/services                                   
else                                                                                                                      
  echo 'AUTONFS_MOUNTS=${mounts}' >> /etc/default/services                                                          
fi                                                                                                                        
";

  $SPOOL .= "                                                                                                                 
if grep -q AUTONFS_INTERVAL /etc/default/services; then                                                                    
  sed -i 's/AUTONFS_INTERVAL=.*/AUTONFS_INTERVAL=${interval}/' /etc/default/services                                     
else                                                                                                                        
  echo 'AUTONFS_INTERVAL=${interval}' >> /etc/default/services                                                            
fi                                                                                                                          
";

  spool_file("${ORDER_SERVICE}_AUTONFS", $SPOOL);                                                                        
  empty_spool();
  $xml_payload = Toggle_Service_xml("AUTONFS", $enabled);

  return $xml_payload;
}


1;
