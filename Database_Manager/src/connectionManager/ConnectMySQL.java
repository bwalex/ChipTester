package connectionManager;

import java.sql.*;

public class ConnectMySQL
{
	private static String userName = "root";
	private static String password = "04123612775";
	private static String url = "jdbc:mysql://localhost/ChipTester";
    
	public static void main (String[] args)
    {
		dropDatabase();
		createDatabase();
		createChipTable();
		insertValues();
    }

public static void createDatabase() {
	Connection conn = null;
	try{
	 conn = DriverManager.getConnection
			("jdbc:mysql://localhost/?user=" + userName + "&password=" + password); 
	 Statement s= conn.createStatement();
			s.executeUpdate("CREATE DATABASE ChipTester");
	}catch (Exception e)
    {
        System.err.println ("Cannot connect to database server or Database already exist");
    }
    finally
    {
        if (conn != null)
        {
            try
            {
                conn.close ();
                System.out.println ("Database connection terminated");
            }
            catch (Exception e) { /* ignore close errors */ }
        }
    }
}	

public static void dropDatabase() {
	Connection conn = null;
	try{
	 conn = DriverManager.getConnection
			("jdbc:mysql://localhost/?user=" + userName + "&password=" + password); 
	 Statement s= conn.createStatement();
			s.executeUpdate("DROP DATABASE IF EXISTS ChipTester");
	}catch (Exception e)
    {
        System.err.println ("Cannot drop database");
    }
    finally
    {
        if (conn != null)
        {
            try
            {
                conn.close ();
                System.out.println ("Database connection terminated");
            }
            catch (Exception e) { /* ignore close errors */ }
        }
    }
}

public static void createChipTable(){
	Connection conn = null;
    try
    {
        Class.forName ("com.mysql.jdbc.Driver").newInstance ();
        conn = DriverManager.getConnection (url, userName, password);
        System.out.println ("Database connection established");
        Statement st = conn.createStatement();
        //Never hard code anything, put this into a property files to be used afterwards
        String query = "CREATE TABLE TEST_ATTRIBUTES (" +
                "id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,"+
                "team_number int,"+ "input_pattern int," + "output_pattern int" 
              + ");";
        st.executeUpdate(query);
    } 
    catch (Exception e)
    {
        System.err.println ("Cannot connect to database server");
    }
    finally
    {
        if (conn != null)
        {
            try
            {
                conn.close ();
                System.out.println ("Database connection terminated");
            }
            catch (Exception e) { /* ignore close errors */ }
        }
    }

}
public static void insertValues() {
	Connection conn = null;
    try
    {
        Class.forName ("com.mysql.jdbc.Driver").newInstance ();
        conn = DriverManager.getConnection (url, userName, password);
        System.out.println ("Database connection established");
        Statement st = conn.createStatement();
        //Never hard code anything, put this into a property files to be used afterwards
        String query = "INSERT INTO TEST_ATTRIBUTES(team_number, input_pattern,output_pattern) VALUES (26, 1111111111, 0101010101)";
        System.out.println(st.executeUpdate(query));
    } 
    catch (Exception e)
    {
        System.err.println ("Cannot connect to database server");
    }
    finally
    {
        if (conn != null)
        {
            try
            {
                conn.close ();
                System.out.println ("Database connection terminated");
            }
            catch (Exception e) { /* ignore close errors */ }
        }
    }

}
}