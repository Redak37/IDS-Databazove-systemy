DROP TABLE Elementy CASCADE CONSTRAINTS;
DROP TABLE Kouzlo CASCADE CONSTRAINTS;
DROP TABLE Vedlej��_element_kouzla CASCADE CONSTRAINTS;
DROP TABLE Magick�_p�edm�t CASCADE CONSTRAINTS;
DROP TABLE Grimo�r CASCADE CONSTRAINTS;
DROP TABLE Kouzla_grimo�ru CASCADE CONSTRAINTS;
DROP TABLE M�sto_prosakuj�c�_magi� CASCADE CONSTRAINTS;
DROP TABLE Kouzeln�k CASCADE CONSTRAINTS;
DROP TABLE Kouzeln�_svitek CASCADE CONSTRAINTS;
DROP TABLE Byl_vlastn�n CASCADE CONSTRAINTS;
DROP TABLE Synergie CASCADE CONSTRAINTS;

DROP SEQUENCE pr_id_seq;

DROP MATERIALIZED VIEW synergie_kouzeln�k�;

CREATE TABLE Elementy (
  N�zev_elementu VARCHAR2(20) NOT NULL PRIMARY KEY,
  Specializace_elementu VARCHAR2(20) NOT NULL,
  Barva_elementu VARCHAR2(20) NOT NULL
);

CREATE TABLE Kouzlo (
  N�zev_kouzla VARCHAR(20) NOT NULL PRIMARY KEY,
  �rove�_slo�itosti_sesl�n� VARCHAR2(1) NOT NULL CHECK(REGEXP_LIKE(�rove�_slo�itosti_sesl�n�, '[A-ES]')),
  Typ VARCHAR2(20) NOT NULL,
  S�la INTEGER,
  Hlavn�_element VARCHAR2(20) NOT NULL,
  FOREIGN KEY (Hlavn�_element) REFERENCES Elementy(N�zev_elementu)
);

CREATE TABLE Vedlej��_element_kouzla (
  N�zev_elementu VARCHAR2(20) NOT NULL,
  N�zev_kouzla VARCHAR2(20) NOT NULL,
  PRIMARY KEY (N�zev_elementu, N�zev_kouzla),
  FOREIGN KEY (N�zev_elementu) REFERENCES Elementy(N�zev_elementu) ON DELETE CASCADE,
  FOREIGN KEY (N�zev_kouzla) REFERENCES Kouzlo(N�zev_kouzla) ON DELETE CASCADE
);

CREATE TABLE Magick�_p�edm�t (
  ID_p�edm�tu INTEGER PRIMARY KEY,
  Je_grimo�rem CHAR(1) NOT NULL CHECK(REGEXP_LIKE(Je_grimo�rem, '[AN]'))
);

CREATE TABLE Grimo�r (
  ID_grimo�ru INTEGER NOT NULL,
  Magick�_energie INTEGER,
  Prim�rn�_element VARCHAR2(20) NOT NULL,
  PRIMARY KEY (ID_grimo�ru),
  FOREIGN KEY (ID_grimo�ru) REFERENCES Magick�_p�edm�t(ID_p�edm�tu) ON DELETE CASCADE,
  FOREIGN KEY (Prim�rn�_element) REFERENCES Elementy(N�zev_elementu)
);

CREATE TABLE Kouzla_grimo�ru (
  ID_grimo�ru INTEGER NOT NULL,
  N�zev_kouzla VARCHAR2(20) NOT NULL,
  PRIMARY KEY (ID_grimo�ru, N�zev_kouzla),
  FOREIGN KEY (ID_grimo�ru) REFERENCES Grimo�r(ID_grimo�ru) ON DELETE CASCADE,
  FOREIGN KEY (N�zev_kouzla) REFERENCES Kouzlo(N�zev_kouzla) ON DELETE CASCADE
);

CREATE TABLE M�sto_prosakuj�c�_magi� (
  GPS_N DECIMAL(10,7) NOT NULL,
  GPS_E DECIMAL(10,7) NOT NULL,
  M�ra_prosakov�n� INTEGER NOT NULL,
  Prosakuj�c�_element VARCHAR2(20) NOT NULL,
  PRIMARY KEY(GPS_N, GPS_E),
  FOREIGN KEY (Prosakuj�c�_element) REFERENCES Elementy(N�zev_elementu) ON DELETE CASCADE
);

CREATE TABLE Kouzeln�k (
  Rodn�_��slo VARCHAR2(10) NOT NULL PRIMARY KEY CHECK(REGEXP_LIKE(Rodn�_��slo, '\d{9}\d?')),
  Jm�no VARCHAR2(64) NOT NULL,
  P��jmen� VARCHAR2(64) NOT NULL,
  Dosa�en�_�rove�_kouzlen� INTEGER NOT NULL,
  V��e_many INTEGER NOT NULL
  --CHECK (REGEXP_LIKE(SUBSTR(Rodn�_��slo, 3, 2), '([05][1-9])|([16][012])')),
  --CHECK (REGEXP_LIKE(SUBSTR(Rodn�_��slo, 5, 2), '([12]\d)|(3[01])|(0[1-9])')),
  --CHECK (REGEXP_LIKE(SUBSTR(Rodn�_��slo, 3, 4), '(([05][13578]|([16][02]))\d\d)|\d[013-9]([0-2]\d|30)|\d2[0-2][0-9]')),
  --CHECK (LENGTH(Rodn�_��slo) = 10 OR REGEXP_LIKE(SUBSTR(Rodn�_��slo, 7, 3), '[1-9]\d\d|\d[1-9]\d|\d\d[1-9]'))
);


CREATE TABLE Kouzeln�_svitek (
  ID_svitku INTEGER NOT NULL,
  N�zev_kouzla VARCHAR2(20) NOT NULL,
  Hodnota INTEGER,
  PRIMARY KEY (ID_svitku),
  FOREIGN KEY (ID_svitku) REFERENCES Magick�_p�edm�t(ID_p�edm�tu) ON DELETE CASCADE,
  FOREIGN KEY (N�zev_kouzla) REFERENCES Kouzlo(N�zev_kouzla)
);

CREATE TABLE Byl_vlastn�n (
  ID_p�edm�tu INTEGER NOT NULL,
  Rodn�_��slo VARCHAR2(10) NOT NULL,
  Od DATE NOT NULL,
  Do DATE,
  PRIMARY KEY (ID_p�edm�tu, Rodn�_��slo),
  FOREIGN KEY (ID_p�edm�tu) REFERENCES Magick�_p�edm�t(ID_p�edm�tu), 
  FOREIGN KEY (Rodn�_��slo) REFERENCES Kouzeln�k(Rodn�_��slo)
);

CREATE TABLE Synergie (
  Kouzeln�k VARCHAR2(10) NOT NULL,
  N�zev_elementu VARCHAR2(20) NOT NULL,
  FOREIGN KEY (N�zev_elementu) REFERENCES Elementy(N�zev_elementu) ON DELETE CASCADE,
  FOREIGN KEY (Kouzeln�k) REFERENCES Kouzeln�k(Rodn�_��slo) ON DELETE CASCADE
);



    
/*Sekvence pro autoinkrementaci ID magick�ch p�edm�t�*/
CREATE SEQUENCE pr_id_seq
    START WITH 1
    INCREMENT BY 1;

/*Trigger pro automatick� generov�n� ID magick�ch p�edm�t�*/
CREATE OR REPLACE TRIGGER predmet_id
    BEFORE INSERT OR UPDATE ON Magick�_p�edm�t
    FOR EACH ROW
BEGIN
	IF :NEW.ID_p�edm�tu is null THEN
	   :NEW.ID_p�edm�tu := pr_id_seq.NEXTVAL;
	END IF;
END;
/

/*Trigger pro kontrolu rodn�ho ��sla kouzeln�ka*/
CREATE OR REPLACE TRIGGER kouzeln�k_rodn�_��slo
    BEFORE INSERT OR UPDATE OF Rodn�_��slo ON Kouzeln�k
    FOR EACH ROW
BEGIN
    IF NOT REGEXP_LIKE(:NEW.Rodn�_��slo, '\d{9}\d?') THEN
        RAISE_APPLICATION_ERROR(1, 'Nesp�vn� rodn� ��slo');
    ELSIF LENGTH(:NEW.Rodn�_��slo) = 10 THEN
        IF MOD(CAST(:NEW.Rodn�_��slo AS INT), 11) <> 0 THEN
            RAISE_APPLICATION_ERROR(1, 'Nesp�vn� rodn� ��slo');
        END IF;
    END IF;
    
    IF NOT (REGEXP_LIKE(SUBSTR(:NEW.Rodn�_��slo, 3, 2), '([05][1-9])|([16][012])')) THEN
            RAISE_APPLICATION_ERROR(1, 'Nesp�vn� rodn� ��slo');
    ELSIF NOT (REGEXP_LIKE(SUBSTR(:NEW.Rodn�_��slo, 5, 2), '([12]\d)|(3[01])|(0[1-9])')) THEN
            RAISE_APPLICATION_ERROR(1, 'Nesp�vn� rodn� ��slo');
    ELSIF NOT (REGEXP_LIKE(SUBSTR(:NEW.Rodn�_��slo, 3, 4), '(([05][13578]|([16][02]))\d\d)|\d[013-9]([0-2]\d|30)|\d2[0-2][0-9]')) THEN
            RAISE_APPLICATION_ERROR(1, 'Nesp�vn� rodn� ��slo');
    ELSIF (NOT LENGTH(:NEW.Rodn�_��slo) = 10) AND (NOT REGEXP_LIKE(SUBSTR(:NEW.Rodn�_��slo, 7, 3), '[1-9]\d\d|\d[1-9]\d|\d\d[1-9]')) THEN
            RAISE_APPLICATION_ERROR(1, 'Nesp�vn� rodn� ��slo');
    END IF;
END;
/


INSERT INTO Elementy (N�zev_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Ohe�', '�tok', 'Karm�nov�');

INSERT INTO Elementy (N�zev_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Voda', 'L��en�', 'Modr�');

INSERT INTO Elementy (N�zev_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Blesk', '�tok', '�lut�');

INSERT INTO Elementy (N�zev_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Zem�', 'Obrana', 'Hn�d�');

INSERT INTO Elementy (N�zev_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Vzduch', 'Support', 'Zelen�');

INSERT INTO Elementy (N�zev_elementu, Specializace_elementu, Barva_elementu)
VALUES ('Sv�tlo', 'Iluze', 'B�l�');



INSERT INTO Kouzlo (N�zev_kouzla, �rove�_slo�itosti_sesl�n�, Typ, S�la, Hlavn�_element)
VALUES ('Armageddon', 'S', '�tok', 9999, 'Ohe�');

INSERT INTO Kouzlo (N�zev_kouzla, �rove�_slo�itosti_sesl�n�, Typ, S�la, Hlavn�_element)
VALUES ('Bleskov� ��p', 'D', '�tok', 50, 'Blesk');

INSERT INTO Kouzlo (N�zev_kouzla, �rove�_slo�itosti_sesl�n�, Typ, S�la, Hlavn�_element)
VALUES ('Lehk� uzdraven�', 'D', 'L��en�', 40, 'Voda');

INSERT INTO Kouzlo (N�zev_kouzla, �rove�_slo�itosti_sesl�n�, Typ, S�la, Hlavn�_element)
VALUES ('Ledov� st�na', 'C', 'Obrana', 25, 'Voda');

INSERT INTO Kouzlo (N�zev_kouzla, �rove�_slo�itosti_sesl�n�, Typ, S�la, Hlavn�_element)
VALUES ('Kamenn� st�na', 'E', 'Obrana', 25, 'Zem�');

INSERT INTO Kouzlo (N�zev_kouzla, �rove�_slo�itosti_sesl�n�, Typ, Hlavn�_element)
VALUES ('Zrychlen�', 'B', 'Support', 'Vzduch');

INSERT INTO Kouzlo (N�zev_kouzla, �rove�_slo�itosti_sesl�n�, Typ, Hlavn�_element)
VALUES ('Zpomalen�', 'B', 'Debuff', 'Zem�');

INSERT INTO Kouzlo (N�zev_kouzla, �rove�_slo�itosti_sesl�n�, Typ, Hlavn�_element)
VALUES ('Oslepen�', 'A', 'Iluze', 'Sv�tlo');



INSERT INTO Vedlej��_element_kouzla (N�zev_elementu, N�zev_kouzla)
VALUES ('Vzduch', 'Ledov� st�na');

INSERT INTO Vedlej��_element_kouzla (N�zev_elementu, N�zev_kouzla)
VALUES ('Zem�', 'Armageddon');

INSERT INTO Vedlej��_element_kouzla (N�zev_elementu, N�zev_kouzla)
VALUES ('Voda', 'Zpomalen�');



INSERT INTO Magick�_p�edm�t (Je_grimo�rem)
VALUES ('A');

INSERT INTO Magick�_p�edm�t (Je_grimo�rem)
VALUES ('A');

INSERT INTO Magick�_p�edm�t (Je_grimo�rem)
VALUES ('A');

INSERT INTO Magick�_p�edm�t (Je_grimo�rem)
VALUES ('A');

INSERT INTO Magick�_p�edm�t (Je_grimo�rem)
VALUES ('N');

INSERT INTO Magick�_p�edm�t (Je_grimo�rem)
VALUES ('N');

INSERT INTO Magick�_p�edm�t (Je_grimo�rem)
VALUES ('N');

INSERT INTO Magick�_p�edm�t (Je_grimo�rem)
VALUES ('N');



INSERT INTO Grimo�r (ID_grimo�ru, Magick�_energie, Prim�rn�_element)
VALUES (1, 654, 'Vzduch');

INSERT INTO Grimo�r (ID_grimo�ru, Magick�_energie, Prim�rn�_element)
VALUES (2, 3, 'Zem�');

INSERT INTO Grimo�r (ID_grimo�ru, Magick�_energie, Prim�rn�_element)
VALUES (3, 131, 'Voda');

INSERT INTO Grimo�r (ID_grimo�ru, Magick�_energie, Prim�rn�_element)
VALUES (4, 1753, 'Ohe�');


INSERT INTO Kouzeln�_svitek (ID_svitku, N�zev_kouzla, Hodnota)
VALUES (5, 'Armageddon', 9999);

INSERT INTO Kouzeln�_svitek (ID_svitku, N�zev_kouzla, Hodnota)
VALUES (6, 'Zrychlen�', 150);

INSERT INTO Kouzeln�_svitek (ID_svitku, N�zev_kouzla, Hodnota)
VALUES (7, 'Zpomalen�', 200);

INSERT INTO Kouzeln�_svitek (ID_svitku, N�zev_kouzla, Hodnota)
VALUES (8, 'Oslepen�', 500);



INSERT INTO Kouzla_grimo�ru (ID_grimo�ru, N�zev_kouzla)
VALUES (1, 'Zrychlen�');

INSERT INTO Kouzla_grimo�ru (ID_grimo�ru, N�zev_kouzla)
VALUES (1, 'Bleskov� ��p');

INSERT INTO Kouzla_grimo�ru (ID_grimo�ru, N�zev_kouzla)
VALUES (1, 'Oslepen�');

INSERT INTO Kouzla_grimo�ru (ID_grimo�ru, N�zev_kouzla)
VALUES (2, 'Kamenn� st�na');

INSERT INTO Kouzla_grimo�ru (ID_grimo�ru, N�zev_kouzla)
VALUES (2, 'Zpomalen�');

INSERT INTO Kouzla_grimo�ru (ID_grimo�ru, N�zev_kouzla)
VALUES (3, 'Lehk� uzdraven�');

INSERT INTO Kouzla_grimo�ru (ID_grimo�ru, N�zev_kouzla)
VALUES (3, 'Ledov� st�na');

INSERT INTO Kouzla_grimo�ru (ID_grimo�ru, N�zev_kouzla)
VALUES (4, 'Armageddon');


INSERT INTO M�sto_prosakuj�c�_magi� (GPS_N, GPS_E, M�ra_prosakov�n�, Prosakuj�c�_element)
VALUES (49.2265439, 16.5971161, 150, 'Zem�');

INSERT INTO M�sto_prosakuj�c�_magi� (GPS_N, GPS_E, M�ra_prosakov�n�, Prosakuj�c�_element)
VALUES (49.2106675, 16.6022367, 80, 'Vzduch');

INSERT INTO M�sto_prosakuj�c�_magi� (GPS_N, GPS_E, M�ra_prosakov�n�, Prosakuj�c�_element)
VALUES (49.19381689, 16.6074144, 120, 'Voda');

INSERT INTO M�sto_prosakuj�c�_magi� (GPS_N, GPS_E, M�ra_prosakov�n�, Prosakuj�c�_element)
VALUES (49.21075810, 16.6188150, 93, 'Ohe�');


INSERT INTO Kouzeln�k (Rodn�_��slo, Jm�no, P��jmen�, Dosa�en�_�rove�_kouzlen�, V��e_many)
VALUES ('9801224103', 'Rastislav', 'Draho�', 8, 100);

INSERT INTO Kouzeln�k (Rodn�_��slo, Jm�no, P��jmen�, Dosa�en�_�rove�_kouzlen�, V��e_many)
VALUES ('9712124323', 'Zden�k', 'Zeman', 11, 200);

INSERT INTO Kouzeln�k (Rodn�_��slo, Jm�no, P��jmen�, Dosa�en�_�rove�_kouzlen�, V��e_many)
VALUES ('9603123321', 'Ond�ej', 'Barto�', 20, 350);

INSERT INTO Kouzeln�k (Rodn�_��slo, Jm�no, P��jmen�, Dosa�en�_�rove�_kouzlen�, V��e_many)
VALUES ('9501057104', 'Bo�ivoj', 'Sk�cel', 3, 70);

INSERT INTO Kouzeln�k (Rodn�_��slo, Jm�no, P��jmen�, Dosa�en�_�rove�_kouzlen�, V��e_many)
VALUES ('9551057120', '��rka', 'Dole�elov�', 5, 150);


INSERT INTO Byl_vlastn�n (ID_p�edm�tu, Rodn�_��slo, Od, Do)
VALUES (1, '9801224103', TO_DATE('2016/02/12 08:00:00', 'yyyy/mm/dd hh24:mi:ss'), TO_DATE('2018/03/13 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastn�n (ID_p�edm�tu, Rodn�_��slo, Od)
VALUES (1, '9712124323', TO_DATE('2015/12/16 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastn�n (ID_p�edm�tu, Rodn�_��slo, Od)
VALUES (2, '9801224103', TO_DATE('2018/03/13 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastn�n (ID_p�edm�tu, Rodn�_��slo, Od)
VALUES (3, '9603123321', TO_DATE('2006/06/06 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastn�n (ID_p�edm�tu, Rodn�_��slo, Od)
VALUES (4, '9551057120', TO_DATE('2017/06/14 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastn�n (ID_p�edm�tu, Rodn�_��slo, Od)
VALUES (5, '9501057104', TO_DATE('2011/02/02 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastn�n (ID_p�edm�tu, Rodn�_��slo, Od)
VALUES (6, '9603123321', TO_DATE('2010/07/07 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));

INSERT INTO Byl_vlastn�n (ID_p�edm�tu, Rodn�_��slo, Od)
VALUES (7, '9501057104', TO_DATE('2012/12/12 08:00:00', 'yyyy/mm/dd hh24:mi:ss'));


INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9801224103', 'Ohe�');

INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9801224103', 'Blesk');

INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9801224103', 'Voda');

INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9712124323', 'Zem�');

INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9712124323', 'Sv�tlo');

INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9603123321', 'Blesk');

INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9603123321', 'Vzduch');

INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9501057104', 'Vzduch');

INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9551057120', 'Sv�tlo');

INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9551057120', 'Voda');

INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9551057120', 'Ohe�');

INSERT INTO Synergie (Kouzeln�k, N�zev_elementu)
VALUES ('9551057120', 'Vzduch');


/*Jm�na kouzeln�k� se synergi� s elementem ohn�*/
SELECT DISTINCT K.Jm�no, K.P��jmen�
FROM Kouzeln�k K JOIN Synergie S ON (S.Kouzeln�k = K.Rodn�_��slo)
WHERE S.N�zev_elementu = 'Ohe�';

/*M�sta, kde lze dob�t grimo�ry ohn� nebo vody*/
SELECT M.GPS_N, M.GPS_E, M.Prosakuj�c�_element
FROM M�sto_prosakuj�c�_magi� M JOIN Grimo�r G ON (M.Prosakuj�c�_element = G.Prim�rn�_element)
WHERE G.Prim�rn�_element = 'Ohe�' OR M.Prosakuj�c�_element = 'Voda';

/*Kter� kouzeln�k m� se kter�mi kouzly sp��zn�nost*/
SELECT K.Jm�no, K.P��jmen�, M.N�zev_kouzla
FROM Kouzeln�k K JOIN Synergie S ON (S.Kouzeln�k = K.Rodn�_��slo) JOIN Kouzlo M ON (S.N�zev_elementu = M.Hlavn�_element)
ORDER BY K.Jm�no;

/*Seznam kouzeln�k� podle po�tu element� se kter�mi maj� sp��zn�nost*/
SELECT K.Jm�no, K.P��jmen�, Count(S.N�zev_elementu) Po�et_element�
FROM Synergie S JOIN Kouzeln�k K ON (S.Kouzeln�k = K.Rodn�_��slo)
GROUP BY K.Jm�no, K.P��jmen�, K.Rodn�_��slo
ORDER BY Po�et_element� DESC;

/*Seznam element� podle po�tu kouzeln�k� se kter�mi maj� sp��zn�nost*/
SELECT S.N�zev_elementu, Count(K.Rodn�_��slo) Po�et_kouzeln�k�
FROM Synergie S JOIN Kouzeln�k K ON (S.Kouzeln�k = K.Rodn�_��slo)
GROUP BY S.N�zev_elementu
ORDER BY Po�et_kouzeln�k� DESC;

/*Seznam kouzeln�k� vlastn�c� svitek*/
SELECT K.Jm�no, K.P��jmen�
FROM Kouzeln�k K
WHERE EXISTS (
    SELECT MP.ID_p�edm�tu
    FROM Magick�_p�edm�t MP JOIN Byl_vlastn�n BV ON (MP.ID_p�edm�tu = BV.ID_p�edm�tu)
    WHERE K.Rodn�_��slo = BV.Rodn�_��slo
    AND MP.Je_grimo�rem = 'N');
    
/*Seznam kouzel, kde typ souhlas� se specializac� jejich prim�rn�ho elementu*/
SELECT K.N�zev_kouzla, K.Typ
FROM Kouzlo K
WHERE K.Hlavn�_element IN (
    SELECT E.N�zev_elementu
    FROM Elementy E
    WHERE E.Specializace_elementu = K.TYP);


SET serveroutput ON;

/*Spo��t�, kolik m� dan� kouzeln�k kouzel svitk� ve sv�ch grim�rech*/
CREATE OR REPLACE PROCEDURE Po�et_kouzel(Rodn�_��slo VARCHAR2)
IS
CURSOR kouzla IS SELECT *
FROM Magick�_p�edm�t MP JOIN BYL_vlastn�n BV ON (BV.Rodn�_��slo = Rodn�_��slo AND MP.ID_p�edm�tu = BV.ID_p�edm�tu)
    LEFT JOIN Kouzla_Grimo�ru KG ON (MP.ID_p�edm�tu = KG.ID_grimo�ru);
	tmp kouzla%ROWTYPE;
    grimo�r NUMBER;
    svitek NUMBER;
BEGIN
    grimo�r := 0;
    svitek := 0;
    OPEN kouzla;
    LOOP
        FETCH kouzla INTO tmp;
        EXIT WHEN kouzla%NOTFOUND;
        IF tmp.Do is null then
            IF (tmp.Je_grimo�rem = 'A') THEN
                grimo�r := grimo�r + 1;
            ELSE
                svitek := svitek + 1;
            END IF;
        END IF;
    END LOOP;
    ClOSE kouzla;
    dbms_output.put_line('Kouzeln�k m� ve sv�ch griom�rech ' || grimo�r || ' kouzel a na svitc�ch ' || svitek || ' kouzel.');

    EXCEPTION
        WHEN OTHERS THEN
            Raise_Application_Error(-20202, 'Nastala chyba!');
END;
/

/*Zjist� pr�m�rnou hodnotu svitku a po�et svitk� s celkovou hodnotou svitk� dan�ho kouzeln�ka*/
CREATE OR REPLACE PROCEDURE Cena_svitk�(Rodn�_��slo VARCHAR2)
IS
CURSOR cena IS SELECT *
FROM Kouzeln�_svitek KS LEFT JOIN Byl_vlastn�n BV ON (KS.ID_svitku = BV.ID_p�edm�tu);
	tmp cena%ROWTYPE;
    pr�m�rn�_cena NUMBER;
    celkov�_cena NUMBER;
    celkov�_cena_k NUMBER;
    po�et NUMBER;
    po�et_k NUMBER;
BEGIN
    celkov�_cena := 0;
    celkov�_cena_k := 0;
    po�et := 0;
    po�et_k := 0;
    OPEN cena;
    LOOP
        FETCH cena INTO tmp;
        EXIT WHEN cena%NOTFOUND;
        IF tmp.Do is null then
            po�et := po�et + 1;
            celkov�_cena := celkov�_cena + tmp.hodnota;
            IF (tmp.Rodn�_��slo = Rodn�_��slo) THEN
                po�et_k := po�et_k + 1;
                celkov�_cena_k := celkov�_cena_k + tmp.hodnota;
            END IF;
        END IF;
    END LOOP;
    pr�m�rn�_cena := ROUND(celkov�_cena / po�et);
    ClOSE cena;
    dbms_output.put_line('Celkov� hodnota dostupn�ch svitk� je: ' || celkov�_cena ||' Pr�m�rn� hodnota svitku je: ' || pr�m�rn�_cena || '.');
    dbms_output.put_line('Tento kouzeln�k vlastn� ' || po�et_k ||' svitk� s celkovou hodnotou: ' || celkov�_cena_k || '.');

    EXCEPTION
        WHEN ZERO_DIVIDE THEN
            dbms_output.put_line('Hodnota svitk� je nevy��sliteln�');
        WHEN OTHERS THEN
            Raise_Application_Error(-20202, 'Nastala chyba!');
END;
/

/*Uk�zka spu�t�n� procedur*/
EXECUTE Po�et_kouzel('9603123321');
EXECUTE Cena_svitk�('9603123321');


EXPLAIN PLAN FOR
    /*Seznam kouzeln�k� podle po�tu element�, se kter�mi maj� sp��zn�nost*/
    SELECT K.Jm�no, K.P��jmen�, Count(S.N�zev_elementu) Po�et_element�
    FROM Synergie S JOIN Kouzeln�k K ON (S.Kouzeln�k = K.Rodn�_��slo)
    GROUP BY K.Jm�no, K.P��jmen�, K.Rodn�_��slo
    ORDER BY Po�et_element� DESC;
SELECT plan_table_output FROM table (dbms_xplan.display());

CREATE INDEX rc_kouzelnik ON Synergie(Kouzeln�k);

EXPLAIN PLAN FOR
    /*Seznam kouzeln�k� podle po�tu element�, se kter�mi maj� sp��zn�nost*/
    SELECT K.Jm�no, K.P��jmen�, Count(S.N�zev_elementu) Po�et_element�
    FROM Synergie S JOIN Kouzeln�k K ON (S.Kouzeln�k = K.Rodn�_��slo)
    GROUP BY K.Jm�no, K.P��jmen�, K.Rodn�_��slo
    ORDER BY Po�et_element� DESC;
SELECT plan_table_output FROM table (dbms_xplan.display());

/*Pr�va pro p��stup k tabulk�m*/
GRANT SELECT ON Elementy                TO xosker03;
GRANT SELECT ON Kouzlo                  TO xosker03;
GRANT SELECT ON Vedlej��_element_kouzla TO xosker03;
GRANT SELECT ON Synergie                TO xosker03;

GRANT ALL ON Magick�_p�edm�t            TO xosker03;
GRANT ALL ON Grimo�r                    TO xosker03;
GRANT ALL ON Kouzla_grimo�ru            TO xosker03;
GRANT ALL ON M�sto_prosakuj�c�_magi�    TO xosker03;
GRANT ALL ON Kouzeln�k                  TO xosker03;
GRANT ALL ON Kouzeln�_svitek            TO xosker03;
GRANT ALL ON Byl_vlastn�n               TO xosker03;

/*Pr�va pro spu�t�n� procedur*/
GRANT EXECUTE ON Cena_svitk�            TO xosker03;
GRANT EXECUTE ON Po�et_kouzel           TO xosker03;


CREATE MATERIALIZED VIEW synergie_kouzeln�k� 
CACHE
BUILD IMMEDIATE
ENABLE QUERY REWRITE
AS SELECT xducho07.K.Rodn�_��slo, xducho07.K.Jm�no, xducho07.K.P��jmen�, xducho07.M.N�zev_kouzla
FROM xducho07.Kouzeln�k K JOIN xducho07.Synergie S ON (xducho07.S.Kouzeln�k = xducho07.K.Rodn�_��slo) JOIN Kouzlo M ON (xducho07.S.N�zev_elementu = xducho07.M.Hlavn�_element)
ORDER BY xducho07.K.Jm�no;

GRANT ALL ON synergie_kouzeln�k� TO xosker03;

select * from synergie_kouzeln�k�;

INSERT INTO Kouzlo (N�zev_kouzla, �rove�_slo�itosti_sesl�n�, Typ, Hlavn�_element)
VALUES ('HokusPokus', 'A', 'Iluze', 'Sv�tlo');

select * from synergie_kouzeln�k�;