const Map<String, Map<String, String>> appDictionary = {
  'ENGLISH': {
    'yes': 'Yes',
    'no': 'No',
    'not_specified': 'Not specified',
    'expectations_partner_preferences': 'Expectations & Partner Preferences',
    'other_preferences': 'Other Preferences',
    'preferred_age': 'Preferred Age',
    'preferred_education': 'Preferred Education',
    'preferred_location': 'Preferred Location',
    'preferred_occupation': 'Preferred Occupation',
    'any': 'Any',
    'to': 'to',

    // Male questions
    'q1_m':
        'Are you willing to stay at your partner\'s house to take care of her parents if needed?',
    'q2_m':
        'Will you fully support your partner to pursue her career and job after marriage?',
    'q3_m':
        'Are you interested in helping your partner with household chores and family matters?',
    'q4_m':
        'Do you want to speak directly with your partner to understand each other before marriage?',
    'q5_m': 'Are you ready to share the responsibilities of children together?',
    'q6_m':
        'Will you have any issues if your partner earns more or has a higher job position than you?',
    'q7_m':
        'Do you prefer taking major family decisions only after consulting your partner?',
    'q8_m':
        'Are you willing to relocate abroad or to another place for work after marriage?',
    'q9_m':
        'Do you have any objections to your partner giving her own earnings to her family?',
    'q10_m':
        'Are you ready to openly disclose any financial liabilities or debts to your partner before marriage?',

    // Female questions
    'q1_f':
        'Are you interested in living together in a Joint Family with your husband\'s parents after marriage?',
    'q2_f':
        'Are you ready to relocate abroad or to another place if required by your husband\'s job?',
    'q3_f':
        'Do you intend to manage both your job and family responsibilities together after marriage?',
    'q4_f':
        'Do you want to speak directly with your partner to understand each other before marriage?',
    'q5_f':
        'Do you prefer to move out and live in a Nuclear Family after marriage?',
    'q6_f':
        'Do you prefer sharing the financial matters of the family together?',
    'q7_f':
        'Will you have any difficulty accepting a partner with Night Shift jobs or jobs requiring frequent travel?',
    'q8_f':
        'Do you prefer taking major family decisions only after consulting your partner?',
    'q9_f':
        'Are you ready to openly disclose any financial liabilities or debts to your partner before marriage?',
    'q10_f':
        'Are you a person who likes to travel and socialize with your partner during holidays?',
  },
  'MALAYALAM': {
    'yes': 'അതെ',
    'no': 'അല്ല',
    'not_specified': 'വ്യക്തമാക്കിയിട്ടില്ല',
    'expectations_partner_preferences': 'പ്രതീക്ഷകളും പങ്കാളി മുൻഗണനകളും',
    'other_preferences': 'മറ്റ് മുൻഗണനകൾ',
    'preferred_age': 'പ്രായം (മുൻഗണന)',
    'preferred_education': 'വിദ്യാഭ്യാസം (മുൻഗണന)',
    'preferred_location': 'സ്ഥലം (മുൻഗണന)',
    'preferred_occupation': 'ജോലി (മുൻഗണന)',
    'any': 'ഏതെങ്കിലും',
    'to': 'മുതൽ',

    // Male questions
    'q1_m':
        'വിവാഹശേഷം പങ്കാളിയുടെ മാതാപിതാക്കളെ നോക്കേണ്ട സാഹചര്യമുണ്ടായാൽ അവരുടെ വീട്ടിൽ താമസിക്കാൻ സമ്മതമാണോ?',
    'q2_m':
        'വിവാഹശേഷവും പങ്കാളിക്ക് താല്പര്യമുള്ള ജോലി ചെയ്യാനും കരിയറിൽ മുന്നോട്ട് പോകാനും പൂർണ്ണ പിന്തുണ നൽകുമോ?',
    'q3_m':
        'വീട്ടുജോലികളിലും കുടുംബകാര്യങ്ങളിലും പങ്കാളിയെ സഹായിക്കാൻ താല്പര്യമുണ്ടോ?',
    'q4_m':
        'വിവാഹത്തിന് മുൻപ് പങ്കാളിയുമായി നേരിട്ട് സംസാരിച്ച് പരസ്പരം മനസ്സിലാക്കാൻ താല്പര്യമുണ്ടോ?',
    'q5_m':
        'കുട്ടികളുടെ ഉത്തരവാദിത്തങ്ങളും കാര്യങ്ങളും രണ്ടുപേരും ഒരുമിച്ച് പങ്കിടാൻ തയ്യാറാണോ?',
    'q6_m':
        'പങ്കാളിക്ക് നിങ്ങളേക്കാൾ കൂടുതൽ ശമ്പളമോ ഉയർന്ന ജോലിയോ ഉണ്ടാകുന്നതിൽ ബുദ്ധിമുട്ടുണ്ടോ?',
    'q7_m':
        'കുടുംബത്തിലെ വലിയ തീരുമാനങ്ങൾ പങ്കാളിയോട് ആലോചിച്ച ശേഷം മാത്രം എടുക്കാൻ താല്പര്യപ്പെടുന്ന ആളാണോ?',
    'q8_m':
        'വിവാഹശേഷം ജോലിയുടെ ഭാഗമായി വിദേശത്തോ മറ്റ് നാട്ടിലോ മാറി താമസിക്കാൻ സമ്മതമാണോ?',
    'q9_m':
        'പങ്കാളിക്ക് സ്വന്തമായി സമ്പാദിക്കുന്ന പണം അവളുടെ വീട്ടുകാർക്ക് നൽകുന്നതിൽ നിങ്ങൾക്ക് എതിർപ്പുണ്ടോ?',
    'q10_m':
        'വിവാഹത്തിന് മുൻപ് നിങ്ങൾക്കുള്ള സാമ്പത്തിക ബാധ്യതകളോ കടങ്ങളോ ഉണ്ടെങ്കിൽ അത് പങ്കാളിയോട് തുറന്നു പറയാൻ തയ്യാറാണോ?',

    // Female questions
    'q1_f':
        'വിവാഹശേഷം ഭർത്താവിന്റെ മാതാപിതാക്കളോടും കുടുംബത്തോടും ഒപ്പം ഒരുമിച്ച് (Joint Family) ജീവിക്കാൻ താല്പര്യമുണ്ടോ?',
    'q2_f':
        'ഭർത്താവിന്റെ ജോലിയുടെ ഭാഗമായി മറ്റൊരു നാട്ടിലേക്കോ വിദേശത്തേക്കോ മാറിത്താമസിക്കേണ്ടി വന്നാൽ അതിന് തയ്യാറാണോ?',
    'q3_f':
        'വിവാഹശേഷം ജോലിക്ക് പോകുന്നതിനൊപ്പം കുടുംബത്തിലെ ഉത്തരവാദിത്തങ്ങളും ഒരുമിച്ച് കൊണ്ടുപോകാൻ താല്പര്യപ്പെടുന്നുണ്ടോ?',
    'q4_f':
        'വിവാഹത്തിന് മുൻപ് പങ്കാളിയുമായി നേരിട്ട് സംസാരിച്ച് പരസ്പരം മനസ്സിലാക്കാൻ താല്പര്യമുണ്ടോ?',
    'q5_f':
        'വിവാഹശേഷം ഒരുമിച്ച് മാറി താമസിക്കാനാണോ (Nuclear Family) കൂടുതൽ മുൻഗണന നൽകുന്നത്?',
    'q6_f':
        'കുടുംബത്തിന്റെ സാമ്പത്തിക കാര്യങ്ങൾ രണ്ടുപേരും ഒരുമിച്ച് പങ്കിട്ട് കൊണ്ടുപോകാൻ താല്പര്യപ്പെടുന്നുണ്ടോ?',
    'q7_f':
        'ഷിഫ്റ്റ് ജോലികളോ (Night Shift) കൂടുതൽ യാത്രകൾ വേണ്ടിവരുന്ന ജോലികളോ ഉള്ള പങ്കാളിയെ സ്വീകരിക്കാൻ ബുദ്ധിമുട്ടുണ്ടോ?',
    'q8_f':
        'കുടുംബത്തിലെ വലിയ തീരുമാനങ്ങൾ പങ്കാളിയോട് ആലോചിച്ച ശേഷം മാത്രം എടുക്കാൻ താല്പര്യപ്പെടുന്ന ആളാണോ?',
    'q9_f':
        'വിവാഹത്തിന് മുൻപ് നിങ്ങൾക്കുള്ള സാമ്പത്തിക ബാധ്യതകളോ കടങ്ങളോ ഉണ്ടെങ്കിൽ അത് പങ്കാളിയോട് തുറന്നു പറയാൻ തയ്യാറാണോ?',
    'q10_f':
        'അവധി ദിവസങ്ങളിൽ പങ്കാളിയോടൊപ്പം യാത്രകൾ ചെയ്യാനും സോഷ്യൽ ആകാനും ഇഷ്ടപ്പെടുന്ന ആളാണോ നിങ്ങൾ?',
  },
  'HINDI': {
    'yes': 'हाँ',
    'no': 'नहीं',
    'not_specified': 'निर्दिष्ट नहीं',
    'expectations_partner_preferences': 'अपेक्षाएं और साथी की प्राथमिकताएं',
    'other_preferences': 'अन्य प्राथमिकताएं',
    'preferred_age': 'आयु प्राथमिकता',
    'preferred_education': 'शिक्षा प्राथमिकता',
    'preferred_location': 'स्थान प्राथमिकता',
    'preferred_occupation': 'व्यवसाय प्राथमिकता',
    'any': 'कोई भी',
    'to': 'से',

    // Hindi translation of male questions (approximate logic for demonstration)
    'q1_m':
        'क्या आप जरूरत पड़ने पर अपने साथी के माता-पिता की देखभाल के लिए उनके घर पर रहने को तैयार हैं?',
    'q2_m':
        'क्या आप शादी के बाद अपने साथी को उनके करियर और नौकरी के लिए पूरा समर्थन देंगे?',
    'q3_m':
        'क्या आप घरेलू कामकाज और पारिवारिक मामलों में अपने साथी की मदद करना चाहते हैं?',
    'q4_m':
        'क्या आप शादी से पहले अपने साथी से सीधे बात करके एक-दूसरे को समझना चाहते हैं?',
    'q5_m':
        'क्या आप बच्चों की जिम्मेदारियों को एक साथ साझा करने के लिए तैयार हैं?',
    'q6_m':
        'क्या आपको कोई समस्या होगी यदि आपका साथी आपसे अधिक कमाता है या उसकी नौकरी का पद आपसे ऊँचा है?',
    'q7_m':
        'क्या आप केवल अपने साथी से सलाह लेने के बाद ही प्रमुख पारिवारिक निर्णय लेना पसंद करते हैं?',
    'q8_m':
        'क्या आप शादी के बाद काम के लिए विदेश या किसी अन्य स्थान पर जाने के लिए तैयार हैं?',
    'q9_m':
        'क्या आपको अपने साथी द्वारा अपनी कमाई अपने परिवार को देने पर कोई आपत्ति है?',
    'q10_m':
        'क्या आप शादी से पहले अपने साथी को किसी भी वित्तीय देनदारी या ऋण का खुलासा करने के लिए तैयार हैं?',

    // Hindi translation of female questions
    'q1_f':
        'क्या आप शादी के बाद अपने पति के माता-पिता के साथ संयुक्त परिवार (Joint Family) में रहने के इच्छुक हैं?',
    'q2_f':
        'यदि आपके पति की नौकरी की आवश्यकता हो, तो क्या आप विदेश या किसी अन्य स्थान पर जाने के लिए तैयार हैं?',
    'q3_f':
        'क्या आप शादी के बाद अपनी नौकरी और पारिवारिक जिम्मेदारियों दोनों को एक साथ प्रबंधित करने का इरादा रखती हैं?',
    'q4_f':
        'क्या आप शादी से पहले अपने साथी से सीधे बात करके एक-दूसरे को समझना चाहते हैं?',
    'q5_f':
        'क्या आप शादी के बाद एक परमाणु परिवार (Nuclear Family) में रहना पसंद करते हैं?',
    'q6_f':
        'क्या आप परिवार के वित्तीय मामलों को एक साथ साझा करना पसंद करते हैं?',
    'q7_f':
        'क्या आपको नाइट शिफ्ट की नौकरी या लगातार यात्रा वाली नौकरी करने वाले साथी को स्वीकार करने में कोई कठिनाई होगी?',
    'q8_f':
        'क्या आप केवल अपने साथी से सलाह लेने के बाद ही प्रमुख पारिवारिक निर्णय लेना पसंद करते हैं?',
    'q9_f':
        'क्या आप शादी से पहले अपने साथी को किसी भी वित्तीय देनदारी या ऋण का खुलासा करने के लिए तैयार हैं?',
    'q10_f':
        'क्या आप एक ऐसे व्यक्ति हैं जो छुट्टियों के दौरान अपने साथी के साथ यात्रा करना और सामाजिककरण करना पसंद करते हैं?',
  },
};
