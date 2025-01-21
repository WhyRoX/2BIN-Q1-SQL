import java.sql.*;

import java.util.Scanner;

public class Main {
    private static final String URL = "jdbc:postgresql://localhost:5432/examsept2024";
    private static final String USER = "postgres";
    private static final String PASSWORD = "EH110304_$$";

    public static void main(String[] args) throws RuntimeException {
        Scanner scanner = new Scanner(System.in);
        System.out.println("Donnez une natioalite : ");
        String scan = scanner.nextLine();

        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD)) {
            String query = "SELECT nom, prenom, niveau "
                            + "FROM examen.vue "
                            + "WHERE nationalite = ? ORDER BY nom, prenom";
            try (PreparedStatement stmt = conn.prepareStatement(query)){
                stmt.setString(1, scan);
                try (ResultSet rs = stmt.executeQuery()){
                    System.out.println("Result natio : " + scan);

                    while(rs.next()) {
                        String nom = rs.getString("nom");
                        String prenom = rs.getString("prenom");
                        int niveau = rs.getInt("niveau");

                        System.out.println("Nom : " + rs.getString(1) + " ,prenom : " + prenom + ", niveau : " + niveau);
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}