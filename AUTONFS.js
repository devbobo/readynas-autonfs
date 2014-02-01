self.AUTONFS_preaction = function()
{
}

self.AUTONFS_onloadaction = function()
{
}

self.AUTONFS_enable = function()
{
  document.getElementById('BUTTON_AUTONFS_APPLY').disabled = false;
  var fileserver = document.getElementById('AUTONFS_FILESERVER');
  if (fileserver)
  {
    fileserver.disabled = false;
  }
  var mountopts = document.getElementById('AUTONFS_MOUNTOPTS');                                                                        
  if (mountopts)                                                                                                                        
  {                                                                                                                                      
    mountopts.disabled = false;                                                                                                         
  } 
  var mounts = document.getElementById('AUTONFS_MOUNTS');
  if (mounts)
  {
    mounts.disabled = false;
  }
  var interval = document.getElementById('AUTONFS_INTERVAL');
  if (interval)
  {
    interval.disabled = false;
  }
}

self.AUTONFS_remove = function()
{
  if( !confirm(S['CONFIRM_REMOVE_ADDON']) )
  {
    return;
  }
  
  var set_url;
  
  if ( confirm(S['CONFIRM_KEEP_ADDON_DATA']) )
  {
    set_url = NasState.otherAddOnHash['AUTONFS'].DisplayAtom.set_url
                + '?OPERATION=set&command=RemoveAddOn&data=preserve';
  }
  else
  {
    set_url = NasState.otherAddOnHash['AUTONFS'].DisplayAtom.set_url
                + '?OPERATION=set&command=RemoveAddOn&data=remove';
  }

  applyChangesAsynch(set_url,  AUTONFS_handle_remove_response);
}

self.AUTONFS_handle_remove_response = function()
{
  if ( httpAsyncRequestObject && 
      httpAsyncRequestObject.readyState && 
      httpAsyncRequestObject.readyState == 4 ) 
  {
    if ( httpAsyncRequestObject.responseText.indexOf('<payload>') != -1 )
    {
       showProgressBar('default');
       xmlPayLoad  = httpAsyncRequestObject.responseXML;
       var status = xmlPayLoad.getElementsByTagName('status').item(0);
       if (!status || !status.firstChild)
       {
          return;
       }

       if ( status.firstChild.data == 'success')
       {
         display_messages(xmlPayLoad);
         updateAddOn('AUTONFS');
         if (!NasState.otherAddOnHash['AUTONFS'])
         {
            remove_element('AUTONFS');
            if (getNumAddOns() == 0 )
            {
               document.getElementById('no_addons').className = 'visible';
            }
         }
         else
         {
           hide_element('AUTONFS_LINK');
         }
       }
       else if (status.firstChild.data == 'failure')
       {
         display_error_messages(xmlPayLoad);
       }
    }
    httpAsyncRequestObject = null;
  }
}

self.AUTONFS_page_change = function()
{
  var id_array = new Array('AUTONFS_FILESERVER', 'AUTONFS_MOUNTOPTS', 'AUTONFS_MOUNTS', 'AUTONFS_INTERVAL');
  for (var ix = 0; ix < id_array.length; ix++ )
  {
     NasState.otherAddOnHash['AUTONFS'].DisplayAtom.fieldHash[id_array[ix]].value = 
     document.getElementById(id_array[ix]).value;
     NasState.otherAddOnHash['AUTONFS'].DisplayAtom.fieldHash[id_array[ix]].modified = true;
  }
}


self.AUTONFS_enable_save_button = function()
{
  document.getElementById('BUTTON_AUTONFS_APPLY').disabled = false;
}

self.AUTONFS_apply = function()
{
   var page_changed = false;
   var set_url = NasState.otherAddOnHash['AUTONFS'].DisplayAtom.set_url;
   var fileserver = document.getElementById('AUTONFS_FILESERVER');
   var mountopts = document.getElementById('AUTONFS_MOUNTOPTS'); 
   var mounts = document.getElementById('AUTONFS_MOUNTS'); 
   var interval = document.getElementById('AUTONFS_INTERVAL');
   if (fileserver || mountopts || mounts || interval)
   {
     var id_array = new Array ('AUTONFS_FILESERVER', 'AUTONFS_MOUNTOPTS', 'AUTONFS_MOUNTS', AUTONFS_INTERVAL);
     for (var ix = 0; ix < id_array.length ; ix ++)
     {
       if (  NasState.otherAddOnHash['AUTONFS'].DisplayAtom.fieldHash[id_array[ix]].modified )
       {
          page_changed = true;
          break;
       }
     }
   }
   var enabled = document.getElementById('CHECKBOX_AUTONFS_ENABLED').checked ? 'checked' :  'unchecked';
   var current_status  = NasState.otherAddOnHash['AUTONFS'].Status;
   if ( page_changed )
   {
      set_url += '?command=ModifyAddOnService&OPERATION=set&' + 
                  NasState.otherAddOnHash['AUTONFS'].DisplayAtom.getApplicablePagePostStringNoQuest('modify') +
                  '&CHECKBOX_AUTONFS_ENABLED=' +  enabled;
      if ( enabled == 'checked' && current_status == 'on' ) 
      {
        set_url += "&SWITCH=NO";
      }
      else
      {
         set_url += "&SWITCH=YES";
      }
   }
   else
   {
      set_url += '?command=ToggleService&OPERATION=set&CHECKBOX_AUTONFS_ENABLED=' + enabled;
   }
   applyChangesAsynch(set_url, AUTONFS_handle_apply_response);
}

self.AUTONFS_handle_apply_response = function()
{
  if ( httpAsyncRequestObject &&
       httpAsyncRequestObject.readyState &&
       httpAsyncRequestObject.readyState == 4 )
  {
    if ( httpAsyncRequestObject.responseText.indexOf('<payload>') != -1 )
    {
      showProgressBar('default');
      xmlPayLoad = httpAsyncRequestObject.responseXML;
      var status = xmlPayLoad.getElementsByTagName('status').item(0);
      if ( !status || !status.firstChild )
      {
        return;
      }

      if ( status.firstChild.data == 'success' )
      {
        var log_alert_payload = xmlPayLoad.getElementsByTagName('normal_alerts').item(0);
        if ( log_alert_payload )
	{
	  var messages = grabMessagePayLoad(log_alert_payload);
	  if ( messages && messages.length > 0 )
	  {
	      if ( messages != 'NO_ALERTS' )
	      {
	        alert (messages);
	      }
	      var success_message_start = AS['SUCCESS_ADDON_START'];
		  success_message_start = success_message_start.replace('%ADDON_NAME%', NasState.otherAddOnHash['AUTONFS'].FriendlyName);
	      var success_message_stop  = AS['SUCCESS_ADDON_STOP'];
		  success_message_stop = success_message_stop.replace('%ADDON_NAME%', NasState.otherAddOnHash['AUTONFS'].FriendlyName);

	      if ( NasState.otherAddOnHash['AUTONFS'].Status == 'off' )
	      {
	        NasState.otherAddOnHash['AUTONFS'].Status = 'on';
	        NasState.otherAddOnHash['AUTONFS'].RunStatus = 'OK';
	        refresh_applicable_pages();
	      }
	      else
	      {
	        NasState.otherAddOnHash['AUTONFS'].Status = 'off';
	        NasState.otherAddOnHash['AUTONFS'].RunStatus = 'not_present';
	        refresh_applicable_pages();
	      }
	    }
        }
      }
      else if (status.firstChild.data == 'failure')
      {
        display_error_messages(xmlPayLoad);
      }
    }
    httpAsyncRequestObject = null;
  }
}

self.AUTONFS_handle_apply_toggle_response = function()
{
  if (httpAsyncRequestObject &&
      httpAsyncRequestObject.readyState &&
      httpAsyncRequestObject.readyState == 4 )
  {
    if ( httpAsyncRequestObject.responseText.indexOf('<payload>') != -1 )
    {
      showProgressBar('default');
      xmlPayLoad = httpAsyncRequestObject.responseXML;
      var status = xmlPayLoad.getElementsByTagName('status').item(0);
      if (!status || !status.firstChild)
      {
        return;
      }
      if ( status.firstChild.data == 'success' )
      {
        display_messages(xmlPayLoad);
      }
      else
      {
        display_error_messages(xmlPayLoad);
      }
    }
  }
}

self.AUTONFS_service_toggle = function()
{
  
  var addon_enabled = document.getElementById('CHECKBOX_AUTONFS_ENABLED').checked ? 'checked' :  'unchecked';
  var set_url    = NasState.otherAddOnHash['AUTONFS'].DisplayAtom.set_url
                   + '?OPERATION=set&command=ToggleService&CHECKBOX_AUTONFS_ENABLED='
                   + addon_enabled;
  
  var xmlSyncPayLoad = getXmlFromUrl(set_url);
  var syncStatus = xmlSyncPayLoad.getElementsByTagName('status').item(0);
  if (!syncStatus || !syncStatus.firstChild)
  {
     return ret_val;
  }

  if ( syncStatus.firstChild.data == 'success' )
  {
    display_messages(xmlSyncPayLoad);
    //if AUTONFS is enabled
    NasState.otherAddOnHash['AUTONFS'].Status = 'on';                                             
    NasState.otherAddOnHash['AUTONFS'].RunStatus = 'OK';                                            
    refresh_applicable_pages();  
    //else if AUTONFS is disabled
    NasState.otherAddOnHash['AUTONFS'].Status = 'off';                    
    NasState.otherAddOnHash['AUTONFS'].RunStatus = 'not_present';         
    refresh_applicable_pages(); 
  }
  else
  {
    display_error_messages(xmlSyncPayLoad);
  }
}

