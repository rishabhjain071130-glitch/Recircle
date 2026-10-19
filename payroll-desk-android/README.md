# Payroll Desk Android App

Yeh Android Studio project aapke diye hue `index.html` ko alag, installable Android app ke roop mein chalata hai. `ReCircle` project alag hi rehta hai.

## APK banana

1. Android Studio mein `payroll-desk-android` folder kholen.
2. Gradle sync complete hone dein.
3. **Build > Build APK(s)** chunein.
4. Debug APK `app/build/outputs/apk/debug/app-debug.apk` mein milegi. Phone par install karne ke liye APK transfer karke kholen.

Command line se Windows par `gradlew.bat assembleDebug` chala sakte hain.

## App mein kya hai

- Original Payroll Desk ke employee, payroll, leave, reports, company settings, staff access aur backup screens.
- Data app ke WebView ke local browser storage mein rehta hai; app data clear/uninstall karne se pehle **Backup file** bana lein.
- Document upload Android file picker se hota hai. Export par Android save-location picker khulta hai. Print Android print dialog kholta hai.
- jsPDF aur ExcelJS source folder mein nahi the. PDF/Excel ke liye HTML unhe CDN se load karne ki koshish karta hai, isliye pehli baar aur in exports ke liye internet zaroori ho sakta hai. JSZip local bundled hai.

## Sudhaar ke sujhaav

1. **Data security:** Aadhaar, PAN, bank aur salary data sensitive hai. Abhi app ka data device par local hai; backup JSON encrypted nahi hai. Encrypted backup aur app lock/biometric gate agla zaroori sudhaar hoga.
2. **Payroll compliance:** PF, ESI, TDS, PT aur overtime ke rules company/location ke hisaab se configure aur date ke saath version hone chahiye. Abhi rates/limits ko CA/payroll expert se verify karke hi payroll final karein.
3. **Audit trail:** Salary, bank details aur employee status ke har badlav ke liye kisne/kab badla uska tamper-resistant log jodein.
4. **Attendance import:** CSV/Excel attendance import, holidays/shift rules aur overtime approval workflow jodein.
5. **Cloud/team sync:** Multi-device access chahiye to authenticated backend, encrypted transport, role checks, server-side audit aur tested backup/restore banayein. Abhi standalone app ka data doosre device par apne aap sync nahi hota.
6. **Release readiness:** App icon/name polish, privacy policy, accessibility, Hindi/English language toggle, crash reporting (sensitive data ke bina) aur Play Store signing tayyar karein.

## Ahm seema

Yeh supplied HTML ka Android wrapper hai, payroll calculation engine ka independent audit nahi. Isse asal salary chalane se pehle apne sample payslip, PF/ESI eligibility, rounding, leave aur full-and-final cases ko parallel manual calculation se verify karein. App mein di gayi login/role settings ko device owner ke khilaaf secure server authentication na samjhein.
