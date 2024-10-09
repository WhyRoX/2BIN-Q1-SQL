-- 1. Quels sont les noms des auteurs habitant la ville de Oakland ?
SELECT au.au_lname
FROM authors au
WHERE au.city = 'Oakland';

-- 2. Donnez les noms et adresses des auteurs dont le prénom commence par la lettre "A".
SELECT au.au_lname, au.address
FROM authors au
WHERE au_fname LIKE 'A%';

-- 3. Donnez les noms et adresses complètes des auteurs qui n'ont pas de numéro de téléphone.
SELECT au.au_lname, au.au_fname, au.address, au.city
FROM authors au
WHERE au.phone IS NULL;

-- 4. Y a-t-il des auteurs californiens dont le numéro de téléphone ne commence pas par "415" ?
SELECT au.au_lname
FROM authors au
WHERE au.state = 'CA' AND au.phone NOT LIKE '415%';

-- 5. Quels sont les auteurs habitant au Bénélux ?
SELECT au.au_lname, au.au_fname
FROM authors au
WHERE au.country = 'BEL' OR au.country = 'NEL' OR au.country = 'LUX';

-- 6. Donnez les identifiants des éditeurs ayant publié au moins un livre de type "psychologie" ?
SELECT DISTINCT ti.pub_id
FROM titles ti
WHERE ti.type = 'psychology';

-- 7. Donnez les identifiants des éditeurs ayant publié au moins un livre de type "psychologie",
-- si l'on omet tous les livres dont le prix est compris entre 10 et 25 $ ?
SELECT DISTINCT ti.pub_id
FROM titles ti
WHERE ti.type = 'psychology' AND ti.price NOT BETWEEN 10 AND 25;

-- 8. Donnez la liste des villes de Californie où l'on peut trouver un (ou plusieurs) auteur(s)
-- dont le prénom est Albert ou dont le nom finit par "er".
SELECT DISTINCT au.city
FROM authors au
WHERE au.city = 'CA' AND au.au_fname = 'Albert' OR au.au_lname LIKE '%er';

-- 9. Donnez tous les couples Etat-pays ("state" - "country") de la table des auteurs,
-- pour lesquels l'Etat est fourni, mais le pays est autre que "USA".
SELECT au.state, au.country
FROM authors au
WHERE au.country <> 'USA';

-- 10. Pour quels types de livres peut-on trouver des livres de prix inférieur à 15 $ ?
SELECT DISTINCT ti.type
FROM titles ti
WHERE ti.price < 15;

--2b IV
-- 1: Affichez la liste de tous les livres, en indiquant pour chacun son titre, son prix et le nom de son éditeur.
SELECT ti.title, ti.price, pub.pub_name
FROM titles ti, publishers pub
WHERE ti.pub_id = pub.pub_id;

-- 2: Affichez la liste de tous les livres de psychologie, en indiquant pour chacun son titre, son prix et le nom de son éditeur.
SELECT ti.title, ti.price, pub.pub_name
FROM titles ti, publishers pub
WHERE ti.pub_id = pub.pub_id and ti.type = 'psychology';

-- 3: Quels sont les auteurs qui ont effectivement écrit un (des) livre(s) présent(s) dans la DB ? Donnez leurs noms et prénoms.
SELECT DISTINCT au.au_lname, au.au_fname
FROM authors au, titleauthor ta
WHERE au.au_id = ta.au_id;

-- 4: Dans quels Etats y a-t-il des auteurs qui ont effectivement écrit un (des) livre(s) présent(s) dans la DB ?
SELECT DISTINCT au.state
FROM authors au, titleauthor ta
WHERE au.au_id = ta.au_id;

-- 5: Donnez les noms et adresses des magasins qui ont commandé des livres en novembre 1991.
SELECT sto.stor_name, sto.stor_address
FROM sales sa, stores sto
WHERE sa.stor_id = sto.stor_id AND date_part('year', sa.date) = 1991 AND date_part('month', sa.date) = 11;

-- 6: Quels sont les livres de psychologie de moins de 20 $ édités par des éditeurs dont le nom ne commence pas par "Algo" ?
SELECT ti.title
FROM titles ti, publishers pub
WHERE ti.pub_id = pub.pub_id AND ti.type = 'psychology' AND ti.price < 20 AND pub.pub_name NOT LIKE 'Algo%';

-- 7: Donnez les titres des livres écrits par (au moins) un auteur californien (state = "CA").
SELECT DISTINCT ti.title
FROM titleauthor ta, authors au, titles ti
WHERE ta.au_id = au.au_id AND ta.title_id = ti.title_id
    AND au.state = 'CA';

-- 8: Quels sont les auteurs qui ont écrit un livre (au moins) publié par un éditeur californien ?
SELECT DISTINCT au.au_lname, au.au_fname
FROM authors au, titleauthor ta, publishers pub, titles ti
WHERE au.au_id = ta.au_id AND pub.pub_id = ti.pub_id AND ta.title_id = ti.title_id
    AND pub.state = 'CA';

-- 9: Quels sont les auteurs qui ont écrit un livre (au moins) publié par un éditeur localisé dans leur Etat ?
SELECT DISTINCT au.au_lname, au.au_fname
FROM authors au, titleauthor ta, publishers pub, titles ti
WHERE au.au_id = ta.au_id AND pub.pub_id = ti.pub_id AND ta.title_id = ti.title_id
    AND pub.state = au.state;

--10. Quels sont les éditeurs dont on a vendu des livres entre le 1/11/1990 et le 1/3/1991 ?
SELECT DISTINCT pub.pub_name
FROM publishers pub, titles ti, salesdetail sd, sales sa
WHERE pub.pub_id = ti.pub_id AND ti.title_id = sd.title_id AND sd.stor_id = sa.stor_id
  AND sa.date > '1990-11-01' AND sa.date < '1991-03-01';

--11. Quels magasins ont vendu des livres contenant le mot "cook" (ou "Cook") dans leur titre ?
SELECT DISTINCT sto.stor_name
FROM stores sto, titles ti, salesdetail sd
WHERE ti.title_id = sd.title_id AND sd.stor_id = sto.stor_id
    AND (ti.title LIKe '%cook%' OR ti.title LIKE '%Cook%');

--12. Y a-t-il des paires de livres publiés par le même éditeur à la même date ?
SELECT ti1.title AS title1, ti2.title AS title2, ti1.pub_id, ti1.pubdate
FROM titles ti1, titles ti2
WHERE ti1.pub_id = ti2.pub_id AND ti1.pubdate = ti2.pubdate AND ti1.title_id < ti2.title_id;

--13 . Y a-t-il des auteurs n'ayant pas publié tous leurs livres chez le même éditeur ?
SELECT DISTINCT au.au_id, au.au_lname, au.au_fname
FROM titles ti, titleauthor ta, authors au
WHERE ta.au_id = au.au_id AND ta.title_id = ti.title_id
GROUP BY au.au_id, au.au_lname, au.au_fname
HAVING COUNT(DISTINCT ti.pub_id) > 1;

--14. Y a-t-il des livres qui ont été vendus avant leur date de parution ?
SELECT DISTINCT ti.title_id
FROM titles ti, sales sa, salesdetail sd
WHERE ti.title_id = sd.title_id AND sa.stor_id = sd.stor_id AND sa.ord_num = sd.ord_num
    AND sa.date < ti.pubdate;

--15. Quels sont les magasins où l'on a vendu des livres écrits par Anne Ringer ?
SELECT DISTINCT sto.stor_name
FROM stores sto, authors au, titleauthor ta, salesdetail sd
WHERE sto.stor_id = sd.stor_id AND sd.title_id = ta.title_id AND ta.au_id = au.au_id
    AND au.au_lname = 'Ringer';

--16. Quels sont les Etats où habite au moins un auteur dont on a vendu des livres en Californie en février 1991 ?
--17. Y a-t-il des paires de magasins situés dans le même Etat, où l'on a vendu des livres du même auteur ?
--18. Trouvez les paires de co-auteurs.

--2dii

--1. Quel est le prix moyen des livres édités par "Algodata Infosystems" ?
SELECT AVG(ti.price)
FROM titles ti, publishers pub
WHERE ti.pub_id = pub.pub_id AND pub.pub_name = 'Algodata Infosystems';

--2. Quel est le prix moyen des livres écrits par chaque auteur ? (Pour chaque auteur, donnez son
--nom, son prénom et le prix moyen de ses livres.)
SELECT AVG(ti.price), au.au_lname, au.au_fname
FROM authors au, titleauthor ta, titles ti
WHERE au.au_id = ta.au_id AND ta.title_id = ti.title_id
GROUP BY au.au_lname, au.au_fname;

--3. Pour chaque livre édité par "Algodata Infosystems", donnez le prix du livre et le nombre
--d'auteurs USE JOINS
SELECT ti.title, ti.price, COUNT(ta.au_id)
FROM titles ti
JOIN titleauthor ta ON ti.title_id = ta.title_id
JOIN publishers pub ON ti.pub_id = pub.pub_id
WHERE pub.pub_name = 'Algodata Infosystems'
GROUP BY ti.price, ti.title;
--4. Pour chaque livre, donnez son titre, son prix, et le nombre de magasins différents où il a été
--vendu.
SELECT ti.title, ti.price, COUNT(sa.stor_id)
FROM titles ti, stores sto, salesdetail sa
WHERE ti.title_id = sa.title_id AND sa.stor_id = sto.stor_id
GROUP BY ti.title, ti.price;

--5 Quels sont les livres qui ont été vendus dans plusieurs magasins ?
SELECT ti.title
FROM titles ti, salesdetail sd
WHERE ti.title_id = sd.title_id
GROUP BY ti.title
HAVING COUNT(DISTINCT sd.stor_id) > 1;
--or using left or right or outer or inner join
SELECT ti.title
FROM titles ti
JOIN salesdetail sd ON ti.title_id = sd.title_id
GROUP BY ti.title
HAVING COUNT(DISTINCT sd.stor_id) > 1;

--6 Pour chaque type de livre, donnez le nombre total de livres de ce type ainsi que leur prix
--moyen.
SELECT tva.type, COUNT(tva.title_id), AVG(tva.price)
FROM titles tva
GROUP BY tva.type;
--7. Pour chaque livre, le "total_sales" devrait normalement être égal au nombre total des ventes
--enregistrées pour ce livre, c'est-à-dire à la somme de toutes les "qty" des détails de vente relatifs à ce
--livre. Vérifiez que c'est bien le cas en affichant pour chaque livre ces deux valeurs côte à côte, ainsi
--que l'identifiant du livre.
SELECT ti.title, ti.title_id, SUM(sd.qty), ti.total_sales
FROM titles ti, salesdetail sd
WHERE ti.title_id = sd.title_id
GROUP BY ti.title, ti.title_id, ti.total_sales;

--8. Même question, mais en n'affichant que les livres pour lesquels il y a erreur.
SELECT ti.title, ti.title_id, SUM(sd.qty), ti.total_sales
FROM titles ti, salesdetail sd
WHERE ti.title_id = sd.title_id
GROUP BY ti.title, ti.title_id, ti.total_sales
HAVING SUM(sd.qty) <> ti.total_sales;
--9. Quels sont les livres ayant été écrits par au moins 3 auteurs ?
SELECT ti.title, COUNT(ta.au_id)
FROM titles ti, titleauthor ta
WHERE ta.title_id = ti.title_id
GROUP BY ti.title
HAVING COUNT(ta.au_id) >= 3;
--10. Combien d'exemplaires de livres d'auteurs californiens édités par des éditeurs californiens at-on vendus dans des magasins californiens ? (Attention, il y a un piège : si vous le détectez, vous
--devrez peut-être attendre un chapitre ultérieur avant de pouvoir résoudre correctement cet
--exercice...)
SELECT count(sd.qty)
FROM salesdetail sd, titles ti, titleauthor ta, authors au, publishers pub, stores sto
WHERE sd.title_id = ti.title_id
  AND ti.title_id = ta.title_id
  AND ta.au_id = au.au_id
  AND ti.pub_id = pub.pub_id
  AND sd.stor_id = sto.stor_id
  AND au.state = 'CA'
  AND pub.state = 'CA'
  AND sto.state = 'CA';
--or using join
SELECT COUNT(sd.qty)
FROM salesdetail sd
JOIN titles ti ON sd.title_id = ti.title_id
JOIN titleauthor ta ON ti.title_id = ta.title_id
JOIN authors au ON ta.au_id = au.au_id
JOIN publishers pub ON ti.pub_id = pub.pub_id
JOIN stores sto ON sd.stor_id = sto.stor_id
WHERE au.state = 'CA' AND pub.state = 'CA' AND sto.state = 'CA';

--2 e iv
--1. Quel est le livre le plus cher publié par l'éditeur "Algodata Infosystems" ?
SELECT max(ti.price)
FROM titles ti, publishers pub
WHERE ti.pub_id = pub.pub_id
  AND pub.pub_name = 'Algodata Infosystems';
--3. Quels sont les livres dont le prix est supérieur à une fois et demi le prix moyen des livres du même type ?
SELECT ti.title, ti.price
FROM titles ti
WHERE ti.price > 1.5 * (SELECT AVG(ti2.price)
                        FROM titles ti2
                        WHERE ti2.type = ti.type);
--5. Quels sont les éditeurs qui n'ont rien édité ?
SELECT pub.pub_name
FROM publishers pub
WHERE NOT EXISTS (SELECT *
                  FROM titles ti
                  WHERE ti.pub_id = pub.pub_id);

--6. Quel est l'éditeur qui a édité le plus grand nombre de livres ?
SELECT pub.pub_name
FROM publishers pub
WHERE pub.pub_id = (SELECT ti.pub_id
                    FROM titles ti
                    GROUP BY ti.pub_id
                    ORDER BY COUNT(ti.title_id) DESC
                    LIMIT 1);
--7. Quels sont les éditeurs dont on n'a vendu aucun livre ?
SELECT pub.pub_name
FROM publishers pub
WHERE NOT EXISTS (SELECT ti.pub_id
                  FROM titles ti);
--8. Quels sont les différents livres écrits par des auteurs californiens, publiés par des éditeurs californiens, et qui n'ont été vendus que dans des magasins californiens ?
SELECT DISTINCT ti.title
FROM titles ti, titleauthor ta, authors au, publishers pub, stores sto, salesdetail sd
WHERE ti.title_id = ta.title_id
  AND ta.au_id = au.au_id
  AND ti.pub_id = pub.pub_id
  AND sd.title_id = ti.title_id
  AND sd.stor_id = sto.stor_id
  AND au.state = 'CA'
  AND pub.state = 'CA'
  AND sto.state = 'CA';
--9. Quel est le titre du livre vendu le plus récemment ? (S'il a des ex-aequo, donnez-les tous.)
SELECT DISTINCT ti.title
FROM titles ti, sales sa
WHERE ti.title_id = (SELECT MAX(sd.title_id)
                     FROM salesdetail sd
                     WHERE sd.ord_num = sa.ord_num
                     ORDER BY sa.date DESC
                     LIMIT 1);
--or
SELECT DISTINCT ti.title
FROM titles ti
JOIN salesdetail sd ON ti.title_id = sd.title_id
JOIN sales sa ON sd.ord_num = sa.ord_num
WHERE sa.date = (SELECT MAX(sa2.date) FROM sales sa2);


--11. Quelles sont les villes de Californie où l'on peut trouver un auteur, mais aucun magasin ?
SELECT DISTINCT au.city
FROM authors au
WHERE au.state = 'CA'
  AND NOT EXISTS (SELECT *
                  FROM stores sto
                  WHERE sto.city = au.city);
--or
SELECT DISTINCT au.city
FROM authors au
WHERE au.state = 'CA'
  AND au.city NOT IN (SELECT sto.city
                      FROM stores sto);
--12. Quels sont les éditeurs localisés dans la ville où il y a le plus d'auteurs ?
SELECT pub.pub_name
FROM publishers pub
WHERE pub.city = (SELECT au.city
                  FROM authors au
                  GROUP BY au.city
                  ORDER BY COUNT(au.au_id) DESC
                  LIMIT 1);
--or
SELECT pub.pub_name
FROM publishers pub
JOIN titles ti ON pub.pub_id = ti.pub_id
JOIN titleauthor ta ON ti.title_id = ta.title_id
JOIN authors au ON ta.au_id = au.au_id
GROUP BY pub.pub_name
ORDER BY COUNT(DISTINCT au.au_id) DESC
LIMIT 1;
--13. Donnez les titres des livres dont tous les auteurs sont californiens.
SELECT DISTINCT ti.title
FROM titles ti, titleauthor ta, authors au
WHERE ti.title_id = ta.title_id
  AND ta.au_id = au.au_id
  AND au.state = 'CA';
--or
SELECT DISTINCT ti.title
FROM titles ti
JOIN titleauthor ta ON ti.title_id = ta.title_id
JOIN authors au ON ta.au_id = au.au_id
WHERE au.state = 'CA';
--15. Quels sont les livres qui n'ont été écrits que par un seul auteur ?
SELECT ti.title
FROM titles ti
WHERE ti.title_id NOT IN (SELECT ti2.title_id
                          FROM titles ti2
                          JOIN titleauthor ta ON ti2.title_id = ta.title_id
                          GROUP BY ti2.title_id
                          HAVING COUNT(ta.au_id) > 1);
--or
SELECT ti.title
FROM titles ti
JOIN titleauthor ta ON ti.title_id = ta.title_id
GROUP BY ti.title
HAVING COUNT(ta.au_id) = 1;
--16. Quels sont les livres qui n'ont qu'un auteur, et tels que cet auteur soit californien ?
SELECT ti.title
FROM titles ti
JOIN titleauthor ta ON ti.title_id = ta.title_id
JOIN authors au ON ta.au_id = au.au_id
WHERE ti.title_id IN (SELECT ti2.title_id
                          FROM titles ti2
                          JOIN titleauthor ta2 ON ti2.title_id = ta2.title_id
                          GROUP BY ti2.title_id
                          HAVING COUNT(ta2.au_id) = 1)
  AND au.state = 'CA';
