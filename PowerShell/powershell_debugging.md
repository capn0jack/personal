#powershell debugging

#clear the error stack
$error.clear

#to get the whole stack trace and everything
$Error[0] | fl * -Force


#go deep into exception and innerexception
#Error[0].exception
#Error[0].exception | fl * -Force
#Error[0].exception.innerexception | fl * -Force


#can do things like sort and format the errors (like if you wanted to get the errors that happened the most)
$Error | group-object | sort-object -property count -descending | format-table -property Count,name -Autosize


#get the stacktrace
$error[0].scriptstacktrace
$error[0].exception.stacktrace


#clear errors
$error.remove($error[0]) #remove specific error
$error.removeat(0) #remove by index
$error.removerange(0,10) #remove range (start and count)
$error.clear() #clear it all


