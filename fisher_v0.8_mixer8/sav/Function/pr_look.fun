
func pr_look(_prompt,_lang)
	dec
		var _prret : 80;
	enddec

	_prret = FSH_PROMPTS & "P" & rjust(_prompt,"0",4) & _lang & ".ul";

	return(_prret);

endfunc

