package chipTest;

import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.Statement;

import configuration.ConfigurationProperties;

public class DUVDescriptor {
	
	private String chipNumber; //The Number of the chip to be tested
	private String teamNumber; //The number of the team
	private String vectorName; //The folder where the data comes from
	private Date configureDate; //The date of the configuration done.
	
	
	private ConfigurationProperties config;
	
	public DUVDescriptor(){
		config = new ConfigurationProperties();
	}
	//Class getters
	private String getChipNumber(){
		return chipNumber;
	}
	private String getTeamNumber(){
		return teamNumber;
	}
	private String getVectorFolder() {
		return vectorName;
	}
	private Date getConfigureDate() {
		return configureDate;
	}
	// Class setters
	private void setChipNumber(String chipNumber){
		this.chipNumber = chipNumber;
	}
	private void setTeamNumber(String teamNumber){
		this.teamNumber = teamNumber;
	}
	private void setVectorFolder(String vectorName) {
		this.vectorName = vectorName;
	}
	private void setConfigureDate(Date configureDate) {
		this.configureDate = configureDate;
	}
	
	public int insertTestConfiguration(String chipNumber, String teamNumber, String vectorName, Date configureDate) {
		Connection conn = null;
		int updateResult = 0;
		setChipNumber(chipNumber);
		setTeamNumber(teamNumber);
		setVectorFolder(vectorName);
		setConfigureDate(configureDate);
	    try
	    {
	        Class.forName (config.getStringValue("JDBC.CONFIGURATION.CLASS")).newInstance ();
	        conn = DriverManager.getConnection (config.getStringValue("DB.CONFIGURATION.URL"),config.getStringValue("DB.CONFIGURATION.USERNAME")
	        		,config.getStringValue("DB.CONFIGURATION.URL"));
	        System.out.println ("Database connection established");
	        Statement st = conn.createStatement();
	        //Query to insert into the database what we desire
	        String query = "INSERT INTO" + config.getStringValue("DB.CONFIGURATION.TABLE")
	        		+ "(" + config.getStringValue("DB.CONFIGURATION.COLUMN.CHIP.NUMBER") + "," +
	        		config.getStringValue("DB.CONFIGURATION.COLUMN.TEAM.NUMBER") + "," + 
	        		config.getStringValue("DB.CONFIGURATION.COLUMN.CONFIGURE.DATE") + "," +
	        		config.getStringValue("DB.CONFIGURATION.COLUMN.VECTOR.NAME") + 
	        		") VALUES (" + chipNumber + "," + teamNumber + "," + configureDate.toString() + 
	        		"," + vectorName + ");";
	        updateResult = st.executeUpdate(query);
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
		return updateResult;
	}
	
}
