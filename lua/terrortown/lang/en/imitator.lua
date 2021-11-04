local L = LANG.GetLanguageTableReference("en")

-- GENERAL ROLE LANGUAGE STRINGS
L[IMITATOR.name] = "Imitator"
L["info_popup_" .. IMITATOR.name] = [[You are an Imitator. You may choose a role to imitate from a limited selection while staying on the Traitor team.]]
L["body_found_" .. IMITATOR.abbr] = "They were Imitator."
L["search_role_" .. IMITATOR.abbr] = "This person was an Imitator!"
L["target_" .. IMITATOR.name] = "Imitator"
L["ttt2_desc_" .. IMITATOR.name] = [[You are an Imitator. You may choose a role to imitate from a limited selection while staying stay on the Traitor team.]]

-- OTHER ROLE LANGUAGE STRINGS
L["IMITATIONS_TITLE_" .. IMITATOR.name] = "Choose Your Role"
L["BAD_IMITATIONS_" .. IMITATOR.name] = "Bad ballot! Please yell at the admin for their blatant disenfranchisement."

-- EVENT STRINGS
-- Need to be very specifically worded, due to how the system translates them.
L["title_event_undec_vote"] = "An Imitator player voted"
L["desc_event_undec_vote"] = "{name} voted to become: {role}."
L["tooltip_undec_vote_score"] = "Voted: {score}"
L["undec_vote_score"] = "Voted:"