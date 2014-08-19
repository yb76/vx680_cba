function prep_txnroc()
  if config.roc == nil or config.roc == "" or tonumber(config.roc) >= 999999 then config.roc = "000001"
  else config.roc = string.format("%06d",tonumber(config.roc) + 1) end
  terminal.SetJsonValue("CONFIG","ROC",config.roc)
  return 0
end
