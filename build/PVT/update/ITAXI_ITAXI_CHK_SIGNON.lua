function itaxi_chk_signon()
  if taxicfg.taxi_no == "" then return itaxi_sign_on() 
  else taxicfg.signed_on = true; return itaxi_finish() end
end
