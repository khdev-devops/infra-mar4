# Python app (Flask + PostgreSQL) på EC2

Detta projekt är en övning i att infrastruktur med **Flask** och **PostgreSQL**. Syftet är att förstå skillnaden mellan applikationslogik och infrastruktur samt hur vi kan automatisera installation och konfiguration med Bash-script.

## Mål med övningen
- Starta en EC2-instans och koppla upp dig med ssh till den
- Hämta detta git repo till EC2-instansen
- Steg för steg fixa problemen och köra appen utan problem

## 1: Förberedelser

### Skapa en EC2-instans
- Namge den till: **Mar4LinuxServer**
- Välj **Amazon Linux 2023**  
- Använd instanstyp **t2.micro**  
- Skapa ny **Key Pair** `mar4`
- Se till att **Security Group** har följande regler:
  - **SSH** (Port 22): Din CloudShell IP (`curl ifconfig.me`)
  - **HTTP** (Port 80): `My IP`

### Koppla upp dig till EC2 via SSH

```bash
ssh -i mar4.pem ec2-user@<EC2-IP>
```
Ersätt `<EC2-IP>` med din instansens publika IP-adress.

## 2: Klona projektet

På EC2-instansen, hämta koden från GitHub:

```bash
sudo dnf install git -y
git clone https://github.com/khdev-devops/infra-mar4.git
cd infra-mar4
```
## 3: Undersök koden

Titta runt i filerna (på github är enklast) för att få ett grepp om vad de olika filerna gör och hur de kan tänkas höra ihop.

## 4: Försök att starta appen

Starta appen genom att köra:
```bash
sudo ./start.sh # sudo för att vi kör på port 80 som är en skyddad port
```

Funkade det inte? Det är nu öventyret börjar!
- Läs felmeddelandena och titta i [start.sh](./start.sh).
- När appen startar utan att krascha så gå till nästa sektion nedan.

## 4: Testa om allt fungerar

### Kontrollera status
Besök appen i din webbläsare:
```
http://<EC2-IP>/
```
Du bör se **steg-för-steg status** om vilka delar som är klara och vilka som saknas. Läs felmeddelanden och försök fixa det steg för steg:
1. Kolla efter `# Steg 1: Kontrollera miljövariabler` i [app.py](app.py)
1. Kolla efter `# Steg 2: Testa anslutning till databasen` i [app.py](app.py)
1. Kolla efter `# Steg 3: Hämta data från databasen` i [app.py](app.py)

Om allt är fixat så skall du kunna se:
```
Hej, Kalle!
```

## 5: Klar? 

Hämta hem projektet med dina uppdateringar (körs i Cloudshell, inte i EC2 instansen terminal):

```bash
scp -i mar4.pem -r ec2-user@<EC2-IP>:~/TODO: .
```

## Feedback?

Gillar du denna övning? Skicka en PR eller förslag på förbättringar!
