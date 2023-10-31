
source "./records/record-define.tcl"
#https://wiki.tcl-lang.org/page/records
record define dbresult data state error_info

proc new_dbresult {data {state success} {errorInfo {}}} {
  record new dbresult $state $data errorInfo
}

proc new_dbresult_error {errorInfo} {
  record new dbresult error {} $errorInfo 
}

proc new_dbresult_success {data} {
  new_dbresult $data 
}

proc dbresult_has_error {rec} {
  expr {[record get rec state]}
}