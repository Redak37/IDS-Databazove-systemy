DROP TABLE Elementy CASCADE CONSTRAINTS;
DROP TABLE Kouzlo CASCADE CONSTRAINTS;
DROP TABLE Vedlejší_element_kouzla CASCADE CONSTRAINTS;
DROP TABLE Magický_pøedmìt CASCADE CONSTRAINTS;
DROP TABLE Grimoár CASCADE CONSTRAINTS;
DROP TABLE Kouzla_grimoáru CASCADE CONSTRAINTS;
DROP TABLE Místo_prosakující_magií CASCADE CONSTRAINTS;
DROP TABLE Kouzelník CASCADE CONSTRAINTS;
DROP TABLE Kouzelný_svitek CASCADE CONSTRAINTS;
DROP TABLE Byl_vlastnìn CASCADE CONSTRAINTS;
DROP TABLE Synergie CASCADE CONSTRAINTS;

DROP SEQUENCE pr_id_seq;

DROP MATERIALIZED VIEW synergie_kouzelníkù;

CREATE TABLE Elementy (
  Název_elementu VARCHAR2(20) NOT NULL PRIMARY KEY,
  Specializace_elementu VARCHAR2(20) NOT NULL,
  Barva_elementu VARCHAR2(20) NOT NULL
);

CREATE TABLE Kouzlo (
  Název_kouzla VARCHAR(20) NOT NULL PRIMARY KEY,
  Úroveò_složitosti_seslání VARCHAR2(1) NOT NULL CHECK(REGEXP_LIKE(Úroveò_složitosti_seslání, '[A-ES]')),
  Typ VARCHAR2(20) NOT NULL,
  Síla INTEGER,
  Hlavní_element VARCHAR2(20) NOT NULL,
  FOREIGN KEY (Hlavní_element) REFERENCES Elementy(Název_elementu)
);

CREATE TABLE Vedlejší_element_kouzla (
  Název_elementu VARCHAR2(20) NOT NULL,
  Název_kouzla VARCHAR2(20) NOT NULL,
  PRIMARY KEY (Název_elementu, Název_kouzla),
  FOREIGN KEY (Název_elementu) REFERENCES Elementy(Název_elementu) ON DELETE CASCADE,
  FOREIGN KEY (Název_kouzla) REFERENCES Kouzlo(Název_kouzla) ON DELETE CASCADE
);

CREATE TABLE Magický_pøedmìt (
  ID_pøedmìtu INTEGER PRIMARY KEY,
  Je_grimoárem CHAR(1) NOT NULL CHECK(REGEXP_LIKE(Je_grimoárem, '[AN]'))
);

CREATE TABLE Grimoár (
  ID_grimoáru INTEGER NOT NULL,
  Magická_energie INTEGER,
  Primární_element VARCHAR2(20) NOT NULL,
  PRIMARY KEY (ID_grimoáru),
  FOREIGN KEY (ID_grimoáru) REFERENCES Magický_pøedmìt(ID_pøedmìtu) ON DELETE CASCADE,
  FOREIGN KEY (Primární_element) REFERENCES Elementy(Název_elementu)
);

CREATE TABLE Kouzla_grimoáru (
  ID_grimoáru INTEGER NOT NULL,
  Název_kouzla VARCHAR2(20) NOT NULL,
  PRIMARY KEY (ID_grimoáru, Název_kouzla),
  FOREIGN KEY (ID_grimoáru) REFERENCES Grimoár(ID_grimoáru) ON DELETE CASCADE,
  FOREIGN KEY (Název_kouzla) REFERENCES Kouzlo(Název_kouzla) ON DELETE CASCADE
);

CREATE TABLE Místo_prosakující_magií (
  GPS_N DECIMAL(10,7) NOT NULL,
  GPS_E DECIMAL(10,7) NOT NULL,
  Míra_prosakování INTEGER NOT NULL,
  Prosakující_element VARCHAR2(20) NOT NULL,
  PRIMARY KEY(GPS_N, GPS_E),
  FOREIGN KEY (Prosakující_element) REFERENCES Elementy(Název_elementu) ON DELETE CASCADE
);

CREATE TABLE Kouzelník (
  Rodné_èíslo VARCHAR2(10) NOT NULL PRIMARY KEY CHECK(REGEXP_LIKE(Rodné_èíslo, '\d{9}\d?')),
  Jméno VARCHAR2(64) NOT NULL,
  Pøíjmení VARCHAR2(64) NOT NULL,
  Dosažená_úroveò_kouzlení INTEGER NOT NULL,
  Výše_many INTEGER NOT NULL
  --CHECK (REGEXP_LIKE(SUBSTR(Rodné_èíslo, 3, 2), '([05][1-9])|([16][012])')),
  --CHECK (REGEXP_LIKE(SUBSTR(Rodné_èíslo, 5, 2), '([12]\d)|(3[01])|(0[1-9])')),
  --CHECK (REGEXP_LIKE(SUBSTR(Rodné_èíslo, 3, 4), '(([05][13578]|([16][02]))\d\d)|\d[013-9]([0-2]\d|30)|\d2[0-2][0-9]')),
  --CHECK (LENGTH(Rodné_èíslo) = 10 OR REGEXP_LIKE(SUBSTR(Rodné_èíslo, 7, 3), '[1-9]\d\d|\d[1-9]\d|\d\d[1-9]'))
);


CREATE TABLE Kouzelný_svitek (
  ID_svitku INTEGER NOT NULL,
  Název_kouzla VARCHAR2(20) NOT NULL,
  Hodnota INTEGER,
  PRIMARY KEY (ID_svitku),
  FOREIGN KEY (ID_svitku) REFERENCES Magický_pøedmìt(ID_pøedmìtu) ON DELETE CASCADE,
  FOREIGN KEY (Název_kouzla) REFERENCES Kouzlo(Název_kouzla)
);

CREATE TABLE Byl_vlastnìn (
  ID_pøedmìtu INTEGER NOT NULL,
  Rodné_èíslo VARCHAR2(10) NOT NULL,
  Od DATE NOT NULL,
  Do DATE,
  PRIMARY KEY (ID_pøedmìtu, Rodné_èíslo),
  FOREIGN KEY (ID_pøedmìtu) REFERENCES Magický_pøedmìt(ID_pøedmìtu), 
  FOREIGN KEY (Rodné_èíslo) REFERENCES Kouzelník(Rodné_èíslo)
);

CREATE TABLE Synergie (
  Kouzelník VARCHAR2(10) NOT NULL,
  Název_elementu VARCHAR2(20) NOT NULL,
  FOREIGN KEY (Název_elementu) REFERENCES Elementy(Název_elementu) ON DELETE CASCADE,
  FOREIGN KEY (Kouzelník) REFERENCES Kouzelník(Rodné_èíslo) ON DELETE CASCADE
);



    
/*Sekvence pro autoinkrementaci ID magických pøedmìtù*/
CREATE SEQUENCE pr_id_seq
    START WITH 1
    INCREMENT BY 1;

/*Trigger pro automatické generování ID magických pøedmìtù*/
CREATE OR REPLACE TRIGGER predmet_id
    BEFORE INSERT OR UPDATE ON Magický_pøedmìt
    FOR EACH ROW
BEGIN
	IF :NEW.ID_pøedmìtu is null THEN
	   :NEW.ID_pøedmìtu := pr_id_seq.NEXTVAL;
	END IF;
END;
/

/*Trigger pro kontrolu rodného èísla kouzelníka*/
CREATE OR REPLACE TRIGGER kouzelník_rodné_èíslo
    BEFORE INSERT OR UPDATE OF Rodné_èíslo ON Kouzelník
    FOR EACH ROW
BEGIN
    IF NOT REGEXP_LIKE(:NEW.Rodné_èíslo, '\d{9}\d?') THEN
        RAISE_APPLICATION_ERROR(1, 'Nespávné rodné èíslo');
    ELSIF LENGTH(:NEW.Rodné_èíslo) = 10 THEN
        IF MOD(CAST(:NEW.Rodné_èíslo AS INT), 11) <> 0 THEN
            RAISE_APPLICATION_ERROR(1, 'Nespávné rodné èíslo');
        END IF;
    END IF;
    
    IF NOT (REGEXP_LIKE(SUBSTR(:NEW.Rodné_èíslo, 3, 2), '([05][1-9])|([16][012])')) THEN
            RAISE_APPLICATION_ERROR(1, 'Nespávné rodné èíslo');
    ELSIF NOT (REGEXP_LIKE(SUBSTR(:NEW.Rodné_èíslo, 5, 2), '([12]\d)|(3[01])|(0[1-9])')) THEN
            RAISE_APPLICATION_ERROR(1, 'Nespávné rodné èíslo');
    ELSIF NOT (REGEXP_LIKE(SUBSTR(:NEW.Rodné_èíslo, 3, 4), '(([05][13578]|([16][02]))\d\d)|\d[013-9]([0-2]\d|30)|\d2[0-2][0-9]')) THEN
            RAISE_APPLICATION_ERROR(1, 'Nespávné rodné èíslo');
    ELSIF (NOT LENGTH(:NEW.Rodné_èíslo) = 10) AND (NOT REGEXP_LIKE(SUBSTR(:NEW.Rodné_èíslo, 7, 3), '[1-9]\d\d|\d[1-9]\d|\d\d[1-9]')) THEN
            RAISE_APPLICATION_ERROR(1, 'Nespávné rodné èíslo');
    END IF;
END;
/


INSERT INTO Elementy (Název_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Oheò', 'Útok', 'Karmínová');

INSERT INTO Elementy (Název_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Voda', 'Léèení', 'Modrá');

INSERT INTO Elementy (Název_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Blesk', 'Útok', 'Žlutá');

INSERT INTO Elementy (Název_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Zemì', 'Obrana', 'Hnìdá');

INSERT INTO Elementy (Název_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Vzduch', 'Support', 'Zelená');

INSERT INTO Elementy (Název_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Svìtlo', 'Iluze', 'Bílá');



INSERT INTO Kouzlo (Název_kouzla, Úroveò_složitosti_seslání, Typ, Síla, Hlavní_element)
VALUES ('Armageddon', 'S', 'Útok', 9999, 'Oheò');

INSERT INTO Kouzlo (Název_kouzla, Úroveò_složitosti_seslání, Typ, Síla, Hlavní_element)
VALUES ('Bleskový šíp', 'D', 'Útok', 50, 'Blesk');

INSERT INTO Kouzlo (Název_kouzla, Úroveò_složitosti_seslání, Typ, Síla, Hlavní_element)
VALUES ('Lehké uzdravení', 'D', 'Léèení', 40, 'Voda');

INSERT INTO Kouzlo (Název_kouzla, Úroveò_složitosti_seslání, Typ, Síla, Hlavní_element)
VALUES ('Ledová stìna', 'C', 'Obrana', 25, 'Voda');

INSERT INTO Kouzlo (Název_kouzla, Úroveò_složitosti_seslání, Typ, Síla, Hlavní_element)
VALUES ('Kamenná stìna', 'E', 'Obrana', 25, 'Zemì');

INSERT INTO Kouzlo (Název_kouzla, Úroveò_složitosti_seslání, Typ, Hlavní_element)
VALUES ('Zrychlení', 'B', 'Support', 'Vzduch');

INSERT INTO Kouzlo (Název_kouzla, Úroveò_složitosti_seslání, Typ, Hlavní_element)
VALUES ('Zpomalení', 'B', 'Debuff', 'Zemì');

INSERT INTO Kouzlo (Název_kouzla, Úroveò_složitosti_seslání, Typ, Hlavní_element)
VALUES ('Oslepení', 'A', 'Iluze', 'Svìtlo');



INSERT INTO Vedlejší_element_kouzla (Název_elementu, Název_kouzla)
VALUES ('Vzduch', 'Ledová stìna');

INSERT INTO Vedlejší_element_kouzla (Název_elementu, Název_kouzla)
VALUES ('Zemì', 'Armageddon');

INSERT INTO Vedlejší_element_kouzla (Název_elementu, Název_kouzla)
VALUES ('Voda', 'Zpomalení');



INSERT INTO Magický_pøedmìt (Je_grimoárem)
VALUES ('A');

INSERT INTO Magický_pøedmìt (Je_grimoárem)
VALUES ('A');

INSERT INTO Magický_pøedmìt (Je_grimoárem)
VALUES ('A');

INSERT INTO Magický_pøedmìt (Je_grimoárem)
VALUES ('A');

INSERT INTO Magický_pøedmìt (Je_grimoárem)
VALUES ('N');

INSERT INTO Magický_pøedmìt (Je_grimoárem)
VALUES ('N');

INSERT INTO Magický_pøedmìt (Je_grimoárem)
VALUES ('N');

INSERT INTO Magický_pøedmìt (Je_grimoárem)
VALUES ('N');



INSERT INTO Grimoár (ID_grimoáru, Magická_energie, Primární_element)
VALUES (1, 654, 'Vzduch');

INSERT INTO Grimoár (ID_grimoáru, Magická_energie, Primární_element)
VALUES (2, 3, 'Zemì');

INSERT INTO Grimoár (ID_grimoáru, Magická_energie, Primární_element)
VALUES (3, 131, 'Voda');

INSERT INTO Grimoár (ID_grimoáru, Magická_energie, Primární_element)
VALUES (4, 1753, 'Oheò');


INSERT INTO Kouzelný_svitek (ID_svitku, Název_kouzla, Hodnota)
VALUES (5, 'Armageddon', 9999);

INSERT INTO Kouzelný_svitek (ID_svitku, Název_kouzla, Hodnota)
VALUES (6, 'Zrychlení', 150);

INSERT INTO Kouzelný_svitek (ID_svitku, Název_kouzla, Hodnota)
VALUES (7, 'Zpomalení', 200);

INSERT INTO Kouzelný_svitek (ID_svitku, Název_kouzla, Hodnota)
VALUES (8, 'Oslepení', 500);



INSERT INTO Kouzla_grimoáru (ID_grimoáru, Název_kouzla)
VALUES (1, 'Zrychlení');

INSERT INTO Kouzla_grimoáru (ID_grimoáru, Název_kouzla)
VALUES (1, 'Bleskový šíp');

INSERT INTO Kouzla_grimoáru (ID_grimoáru, Název_kouzla)
VALUES (1, 'Oslepení');

INSERT INTO Kouzla_grimoáru (ID_grimoáru, Název_kouzla)
VALUES (2, 'Kamenná stìna');

INSERT INTO Kouzla_grimoáru (ID_grimoáru, Název_kouzla)
VALUES (2, 'Zpomalení');

INSERT INTO Kouzla_grimoáru (ID_grimoáru, Název_kouzla)
VALUES (3, 'Lehké uzdravení');

INSERT INTO Kouzla_grimoáru (ID_grimoáru, Název_kouzla)
VALUES (3, 'Ledová stìna');

INSERT INTO Kouzla_grimoáru (ID_grimoáru, Název_kouzla)
VALUES (4, 'Armageddon');


INSERT INTO Místo_prosakující_magií (GPS_N, GPS_E, Míra_prosakování, Prosakující_element)
VALUES (49.2265439, 16.5971161, 150, 'Zemì');

INSERT INTO Místo_prosakující_magií (GPS_N, GPS_E, Míra_prosakování, Prosakující_element)
VALUES (49.2106675, 16.6022367, 80, 'Vzduch');

INSERT INTO Místo_prosakující_magií (GPS_N, GPS_E, Míra_prosakování, Prosakující_element)
VALUES (49.19381689, 16.6074144, 120, 'Voda');

INSERT INTO Místo_prosakující_magií (GPS_N, GPS_E, Míra_prosakování, Prosakující_element)
VALUES (49.21075810, 16.6188150, 93, 'Oheò');


INSERT INTO Kouzelník (Rodné_èíslo, Jméno, Pøíjmení, Dosažená_úroveò_kouzlení, Výše_many)
VALUES ('9801224103', 'Rastislav', 'Drahoš', 8, 100);

INSERT INTO Kouzelník (Rodné_èíslo, Jméno, Pøíjmení, Dosažená_úroveò_kouzlení, Výše_many)
VALUES ('9712124323', 'Zdenìk', 'Zeman', 11, 200);

INSERT INTO Kouzelník (Rodné_èíslo, Jméno, Pøíjmení, Dosažená_úroveò_kouzlení, Výše_many)
VALUES ('9603123321', 'Ondøej', 'Bartoš', 20, 350);

INSERT INTO Kouzelník (Rodné_èíslo, Jméno, Pøíjmení, Dosažená_úroveò_kouzlení, Výše_many)
VALUES ('9501057104', 'Boøivoj', 'Skácel', 3, 70);

INSERT INTO Kouzelník (Rodné_èíslo, Jméno, Pøíjmení, Dosažená_úroveò_kouzlení, Výše_many)
VALUES ('9551057120', 'Šárka', 'Doleželová', 5, 150);


INSERT INTO Byl_vlastnìn (ID_pøedmìtu, Rodné_èíslo, Od, Do)
VALUES (1, '9801224103', TO_DATE('2016/02/12 08:00:00', 'yyyy/mm/dd hh24:mi:ss'), TO_DATE('2018/03/13 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastnìn (ID_pøedmìtu, Rodné_èíslo, Od)
VALUES (1, '9712124323', TO_DATE('2015/12/16 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastnìn (ID_pøedmìtu, Rodné_èíslo, Od)
VALUES (2, '9801224103', TO_DATE('2018/03/13 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastnìn (ID_pøedmìtu, Rodné_èíslo, Od)
VALUES (3, '9603123321', TO_DATE('2006/06/06 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastnìn (ID_pøedmìtu, Rodné_èíslo, Od)
VALUES (4, '9551057120', TO_DATE('2017/06/14 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastnìn (ID_pøedmìtu, Rodné_èíslo, Od)
VALUES (5, '9501057104', TO_DATE('2011/02/02 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastnìn (ID_pøedmìtu, Rodné_èíslo, Od)
VALUES (6, '9603123321', TO_DATE('2010/07/07 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastnìn (ID_pøedmìtu, Rodné_èíslo, Od)
VALUES (7, '9501057104', TO_DATE('2012/12/12 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));


INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9801224103', 'Oheò');

INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9801224103', 'Blesk');

INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9801224103', 'Voda');

INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9712124323', 'Zemì');

INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9712124323', 'Svìtlo');

INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9603123321', 'Blesk');

INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9603123321', 'Vzduch');

INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9501057104', 'Vzduch');

INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9551057120', 'Svìtlo');

INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9551057120', 'Voda');

INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9551057120', 'Oheò');

INSERT INTO Synergie (Kouzelník, Název_elementu)
VALUES ('9551057120', 'Vzduch');


/*Jména kouzelníkù se synergií s elementem ohnì*/
SELECT DISTINCT K.Jméno, K.Pøíjmení
FROM Kouzelník K JOIN Synergie S ON (S.Kouzelník = K.Rodné_èíslo)
WHERE S.Název_elementu = 'Oheò';

/*Místa, kde lze dobít grimoáry ohnì nebo vody*/
SELECT M.GPS_N, M.GPS_E, M.Prosakující_element
FROM Místo_prosakující_magií M JOIN Grimoár G ON (M.Prosakující_element = G.Primární_element)
WHERE G.Primární_element = 'Oheò' OR M.Prosakující_element = 'Voda';

/*Který kouzelník má se kterými kouzly spøíznìnost*/
SELECT K.Jméno, K.Pøíjmení, M.Název_kouzla
FROM Kouzelník K JOIN Synergie S ON (S.Kouzelník = K.Rodné_èíslo) JOIN Kouzlo M ON (S.Název_elementu = M.Hlavní_element)
ORDER BY K.Jméno;

/*Seznam kouzelníkù podle poètu elementù se kterými mají spøíznìnost*/
SELECT K.Jméno, K.Pøíjmení, Count(S.Název_elementu) Poèet_elementù
FROM Synergie S JOIN Kouzelník K ON (S.Kouzelník = K.Rodné_èíslo)
GROUP BY K.Jméno, K.Pøíjmení, K.Rodné_èíslo
ORDER BY Poèet_elementù DESC;

/*Seznam elementù podle poètu kouzelníkù se kterými mají spøíznìnost*/
SELECT S.Název_elementu, Count(K.Rodné_èíslo) Poèet_kouzelníkù
FROM Synergie S JOIN Kouzelník K ON (S.Kouzelník = K.Rodné_èíslo)
GROUP BY S.Název_elementu
ORDER BY Poèet_kouzelníkù DESC;

/*Seznam kouzelníkù vlastnící svitek*/
SELECT K.Jméno, K.Pøíjmení
FROM Kouzelník K
WHERE EXISTS (
    SELECT MP.ID_pøedmìtu
    FROM Magický_pøedmìt MP JOIN Byl_vlastnìn BV ON (MP.ID_pøedmìtu = BV.ID_pøedmìtu)
    WHERE K.Rodné_èíslo = BV.Rodné_èíslo
    AND MP.Je_grimoárem = 'N');
    
/*Seznam kouzel, kde typ souhlasí se specializací jejich primárního elementu*/
SELECT K.Název_kouzla, K.Typ
FROM Kouzlo K
WHERE K.Hlavní_element IN (
    SELECT E.Název_elementu
    FROM Elementy E
    WHERE E.Specializace_elementu = K.TYP);


SET serveroutput ON;

/*Spoèítá, kolik má daný kouzelník kouzel svitkù ve svých grimárech*/
CREATE OR REPLACE PROCEDURE Poèet_kouzel(Rodné_èíslo VARCHAR2)
IS
CURSOR kouzla IS SELECT *
FROM Magický_pøedmìt MP JOIN BYL_vlastnìn BV ON (BV.Rodné_èíslo = Rodné_èíslo AND MP.ID_pøedmìtu = BV.ID_pøedmìtu)
    LEFT JOIN Kouzla_Grimoáru KG ON (MP.ID_pøedmìtu = KG.ID_grimoáru);
	tmp kouzla%ROWTYPE;
    grimoár NUMBER;
    svitek NUMBER;
BEGIN
    grimoár := 0;
    svitek := 0;
    OPEN kouzla;
    LOOP
        FETCH kouzla INTO tmp;
        EXIT WHEN kouzla%NOTFOUND;
        IF tmp.Do is null then
            IF (tmp.Je_grimoárem = 'A') THEN
                grimoár := grimoár + 1;
            ELSE
                svitek := svitek + 1;
            END IF;
        END IF;
    END LOOP;
    ClOSE kouzla;
    dbms_output.put_line('Kouzelník má ve svých griomárech ' || grimoár || ' kouzel a na svitcích ' || svitek || ' kouzel.');

    EXCEPTION
        WHEN OTHERS THEN
            Raise_Application_Error(-20202, 'Nastala chyba!');
END;
/

/*Zjistí prùmìrnou hodnotu svitku a poèet svitkù s celkovou hodnotou svitkù daného kouzelníka*/
CREATE OR REPLACE PROCEDURE Cena_svitkù(Rodné_èíslo VARCHAR2)
IS
CURSOR cena IS SELECT *
FROM Kouzelný_svitek KS LEFT JOIN Byl_vlastnìn BV ON (KS.ID_svitku = BV.ID_pøedmìtu);
	tmp cena%ROWTYPE;
    prùmìrná_cena NUMBER;
    celková_cena NUMBER;
    celková_cena_k NUMBER;
    poèet NUMBER;
    poèet_k NUMBER;
BEGIN
    celková_cena := 0;
    celková_cena_k := 0;
    poèet := 0;
    poèet_k := 0;
    OPEN cena;
    LOOP
        FETCH cena INTO tmp;
        EXIT WHEN cena%NOTFOUND;
        IF tmp.Do is null then
            poèet := poèet + 1;
            celková_cena := celková_cena + tmp.hodnota;
            IF (tmp.Rodné_èíslo = Rodné_èíslo) THEN
                poèet_k := poèet_k + 1;
                celková_cena_k := celková_cena_k + tmp.hodnota;
            END IF;
        END IF;
    END LOOP;
    prùmìrná_cena := ROUND(celková_cena / poèet);
    ClOSE cena;
    dbms_output.put_line('Celková hodnota dostupných svitkù je: ' || celková_cena ||' Prùmìrná hodnota svitku je: ' || prùmìrná_cena || '.');
    dbms_output.put_line('Tento kouzelník vlastní ' || poèet_k ||' svitkù s celkovou hodnotou: ' || celková_cena_k || '.');

    EXCEPTION
        WHEN ZERO_DIVIDE THEN
            dbms_output.put_line('Hodnota svitkù je nevyèíslitelná');
        WHEN OTHERS THEN
            Raise_Application_Error(-20202, 'Nastala chyba!');
END;
/

/*Ukázka spuštìní procedur*/
EXECUTE Poèet_kouzel('9603123321');
EXECUTE Cena_svitkù('9603123321');


EXPLAIN PLAN FOR
    /*Seznam kouzelníkù podle poètu elementù, se kterými mají spøíznìnost*/
    SELECT K.Jméno, K.Pøíjmení, Count(S.Název_elementu) Poèet_elementù
    FROM Synergie S JOIN Kouzelník K ON (S.Kouzelník = K.Rodné_èíslo)
    GROUP BY K.Jméno, K.Pøíjmení, K.Rodné_èíslo
    ORDER BY Poèet_elementù DESC;
SELECT plan_table_output FROM table (dbms_xplan.display());

CREATE INDEX rc_kouzelnik ON Synergie(Kouzelník);

EXPLAIN PLAN FOR
    /*Seznam kouzelníkù podle poètu elementù, se kterými mají spøíznìnost*/
    SELECT K.Jméno, K.Pøíjmení, Count(S.Název_elementu) Poèet_elementù
    FROM Synergie S JOIN Kouzelník K ON (S.Kouzelník = K.Rodné_èíslo)
    GROUP BY K.Jméno, K.Pøíjmení, K.Rodné_èíslo
    ORDER BY Poèet_elementù DESC;
SELECT plan_table_output FROM table (dbms_xplan.display());

/*Práva pro pøístup k tabulkám*/
GRANT SELECT ON Elementy                TO xosker03;
GRANT SELECT ON Kouzlo                  TO xosker03;
GRANT SELECT ON Vedlejší_element_kouzla TO xosker03;
GRANT SELECT ON Synergie                TO xosker03;

GRANT ALL ON Magický_pøedmìt            TO xosker03;
GRANT ALL ON Grimoár                    TO xosker03;
GRANT ALL ON Kouzla_grimoáru            TO xosker03;
GRANT ALL ON Místo_prosakující_magií    TO xosker03;
GRANT ALL ON Kouzelník                  TO xosker03;
GRANT ALL ON Kouzelný_svitek            TO xosker03;
GRANT ALL ON Byl_vlastnìn               TO xosker03;

/*Práva pro spuštìní procedur*/
GRANT EXECUTE ON Cena_svitkù            TO xosker03;
GRANT EXECUTE ON Poèet_kouzel           TO xosker03;


CREATE MATERIALIZED VIEW synergie_kouzelníkù 
CACHE
BUILD IMMEDIATE
ENABLE QUERY REWRITE
AS SELECT xducho07.K.Rodné_èíslo, xducho07.K.Jméno, xducho07.K.Pøíjmení, xducho07.M.Název_kouzla
FROM xducho07.Kouzelník K JOIN xducho07.Synergie S ON (xducho07.S.Kouzelník = xducho07.K.Rodné_èíslo) JOIN Kouzlo M ON (xducho07.S.Název_elementu = xducho07.M.Hlavní_element)
ORDER BY xducho07.K.Jméno;

GRANT ALL ON synergie_kouzelníkù TO xosker03;

select * from synergie_kouzelníkù;

INSERT INTO Kouzlo (Název_kouzla, Úroveò_složitosti_seslání, Typ, Hlavní_element)
VALUES ('HokusPokus', 'A', 'Iluze', 'Svìtlo');

select * from synergie_kouzelníkù;