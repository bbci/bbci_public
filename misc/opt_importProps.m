function props= opt_importProps(props, props2, fieldlist)

misc_checkType(props, 'PROPSPEC');
misc_checkType(props2, 'PROPSPEC');
misc_checkType(fieldlist, 'CELL{CHAR}');

idx_import= ismember(props2(:,1), fieldlist);
props= cat(1, props, props2(idx_import,:));
