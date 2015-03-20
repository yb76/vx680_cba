function do_obj_prchamount()
  if ecrd.AMT then txn.prchamt = ecrd.AMT end
  txn.cashamt = 0
  if not txn.prchamt then txn.prchamt = 0 end
  txn.totalamt = txn.prchamt + txn.cashamt
  return do_obj_swipecard()
end
