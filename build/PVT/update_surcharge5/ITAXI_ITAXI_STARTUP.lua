function itaxi_startup()
  if not taxicfg.signed_on then taxi.finishreturn = true; itaxi_chk_signon(); taxi.finishreturn = false end
  if not taxicfg.registered then taxicfg.registered = true; do_obj_gprs_register() end
  return 0
end
