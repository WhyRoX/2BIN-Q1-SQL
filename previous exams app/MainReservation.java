import java.sql.*;
import java.util.Scanner;

public class Main {
    private static final String url = "jdbc:postgresql://localhost/examjanv2023";
    private static final String user = "postgres";
    private static final String password = "EH110304_$$";


    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        System.out.println("Donnez bloc : ");
        int bloc = scanner.nextInt();

        try (Connection conn = DriverManager.getConnection(url, user, password)){
            String query = "SELECT v.nom, v.date_exam, v.nbLocal FROM examen.vue v "
                    + "WHERE v.bloc = ? ORDER BY v.date_exam";
            try (PreparedStatement stmt = conn.prepareStatement(query)){
                stmt.setInt(1, bloc);
                try (ResultSet rs = stmt.executeQuery()){
                    System.out.println("Examns du bloc " + bloc + " : ");

                    while (rs.next()) {
                        String nom = rs.getString("nom");
                        String date = rs.getString("date_exam");
                        int nbLocal = rs.getInt("nbLocal");

                        System.out.println("Nom : " + nom + " ,date : " + date + " ,nbLocal : " + nbLocal);
                    }
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}