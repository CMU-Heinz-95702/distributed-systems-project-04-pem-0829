// //Peter Muller/pmuller

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.net.*;
import java.util.Map;
import com.google.gson.*;

public class AmiiboSearchApp extends JFrame {
    private JRadioButton rbSeries, rbCharacter, rbGameSeries, rbName, rbType;
    private JTextField txtSearch;
    private JButton btnSearch;
    private JPanel resultsPanel;
    private ButtonGroup bg;
    private JScrollPane scrollPane;

    public AmiiboSearchApp() {
        setTitle("Amiibo Search App");
        setSize(900, 700);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        // Create radio buttons
        rbSeries = new JRadioButton("Series");
        rbCharacter = new JRadioButton("Character");
        rbGameSeries = new JRadioButton("Game Series");
        rbName = new JRadioButton("Name");
        rbType = new JRadioButton("Type");
        bg = new ButtonGroup();
        bg.add(rbSeries);
        bg.add(rbCharacter);
        bg.add(rbGameSeries);
        bg.add(rbName);
        bg.add(rbType);
        rbName.setSelected(true);

        // Search field and button
        txtSearch = new JTextField(20);
        btnSearch = new JButton("Search");

        // Build a single row for controls
        JPanel controlsPanel = new JPanel();
        controlsPanel.setLayout(new FlowLayout(FlowLayout.CENTER));
        controlsPanel.add(new JLabel("Search by: "));
        controlsPanel.add(rbSeries);
        controlsPanel.add(rbCharacter);
        controlsPanel.add(rbGameSeries);
        controlsPanel.add(rbName);
        controlsPanel.add(rbType);
        controlsPanel.add(txtSearch);
        controlsPanel.add(btnSearch);

        // Results area in the center
        resultsPanel = new JPanel();
        resultsPanel.setLayout(new BoxLayout(resultsPanel, BoxLayout.Y_AXIS));
        scrollPane = new JScrollPane(resultsPanel,
                JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED,
                JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
        scrollPane.getVerticalScrollBar().setUnitIncrement(16);

        setLayout(new BorderLayout());
        add(controlsPanel, BorderLayout.NORTH);
        add(scrollPane, BorderLayout.CENTER);

        btnSearch.addActionListener(e -> performSearch());

        setVisible(true);
    }

    private void performSearch() {
        resultsPanel.removeAll();
        resultsPanel.repaint();

        String type = "name";
        if (rbSeries.isSelected()) type = "amiiboSeries";
        else if (rbCharacter.isSelected()) type = "character";
        else if (rbGameSeries.isSelected()) type = "gameseries";
        else if (rbType.isSelected()) type = "type";
        String term = txtSearch.getText().trim();
        if (term.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Please enter a search term.");
            return;
        }
        String apiUrl = "https://www.amiiboapi.com/api/amiibo/?" + type + "=" + encode(term);

        // Show loading message
        JLabel loadingLabel = new JLabel("Loading...");
        loadingLabel.setHorizontalAlignment(JLabel.CENTER);
        resultsPanel.add(loadingLabel);
        resultsPanel.revalidate();
        resultsPanel.repaint();

        SwingWorker<Void, Void> worker = new SwingWorker<Void, Void>() {
            @Override
            protected Void doInBackground() {
                try {
                    URL url = new URL(apiUrl);
                    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                    conn.setRequestMethod("GET");
                    BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                    StringBuilder content = new StringBuilder();
                    String inputLine;
                    while ((inputLine = in.readLine()) != null) {
                        content.append(inputLine);
                    }
//                    System.out.println("Results found: " + counter);
                    in.close();

                    Gson gson = new Gson();
                    AmiiboResponse response = gson.fromJson(content.toString(), AmiiboResponse.class);
                    if (response != null && response.amiibo != null) {
                        System.out.println("Total results: " + response.amiibo.length);
                        int k = Math.min(5, response.amiibo.length);
                        for (int i = 0; i < k; i++) {
                            Amiibo a = response.amiibo[i];
                            System.out.println((i+1) + ". " + a.name + " | " + a.character + " | " + a.gameSeries);
                        }
                    } else {
                        System.out.println("No results returned from API.");
                    }

                    SwingUtilities.invokeLater(() -> {
                        resultsPanel.removeAll();
                        if (response == null || response.amiibo == null || response.amiibo.length == 0) {
                            JLabel label = new JLabel("No results found.");
                            label.setAlignmentX(Component.CENTER_ALIGNMENT);
                            resultsPanel.add(label);
                        } else {
                            for (Amiibo amiibo : response.amiibo) {
                                JPanel amiiboPanel = new JPanel();
                                amiiboPanel.setLayout(new BorderLayout());
                                amiiboPanel.setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));
                                amiiboPanel.setBackground(Color.WHITE);

                                try {
                                    if (amiibo.image != null) {
                                        URL imgUrl = new URL(amiibo.image);
                                        ImageIcon icon = new ImageIcon(imgUrl);
                                        Image img = icon.getImage().getScaledInstance(90, 90, Image.SCALE_SMOOTH);
                                        JLabel imgLabel = new JLabel(new ImageIcon(img));
                                        amiiboPanel.add(imgLabel, BorderLayout.WEST);
                                    } else {
                                        amiiboPanel.add(new JLabel("No image"), BorderLayout.WEST);
                                    }
                                } catch (Exception ex) {
                                    amiiboPanel.add(new JLabel("No image"), BorderLayout.WEST);
                                }
                                String releaseNA = (amiibo.release != null && amiibo.release.get("na") != null)
                                        ? amiibo.release.get("na") : "N/A";
                                JTextArea infoArea = new JTextArea(
                                        "Name: " + amiibo.name + "\n" +
                                                "Character: " + amiibo.character + "\n" +
                                                "Game Series: " + amiibo.gameSeries + "\n" +
                                                "Type: " + amiibo.type + "\n" +
                                                "Amiibo Series: " + amiibo.amiiboSeries + "\n" +
                                                "Release Date (NA): " + releaseNA + "\n"
                                );
                                infoArea.setEditable(false);
                                infoArea.setOpaque(false);
                                infoArea.setBorder(null);
                                infoArea.setFont(new Font("SansSerif", Font.PLAIN, 13));
                                amiiboPanel.add(infoArea, BorderLayout.CENTER);

                                resultsPanel.add(amiiboPanel);
                                resultsPanel.add(Box.createRigidArea(new Dimension(0, 10)));
                            }
                        }
                        resultsPanel.revalidate();
                        resultsPanel.repaint();
                    });
                } catch (Exception ex) {
                    ex.printStackTrace();
                    SwingUtilities.invokeLater(() -> {
                        resultsPanel.removeAll();
                        JLabel errorLabel = new JLabel("Error fetching data from API.");
                        errorLabel.setForeground(Color.RED);
                        errorLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
                        resultsPanel.add(errorLabel);
                        resultsPanel.revalidate();
                        resultsPanel.repaint();
                    });
                }
                return null;
            }
        };
        worker.execute();
    }

    private static String encode(String s) {
        try {
            return URLEncoder.encode(s, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            return s;
        }
    }

    public static class AmiiboResponse {
        Amiibo[] amiibo;
    }
    public static class Amiibo {
        public String name;
        public String head;
        public String character;
        public String gameSeries;
        public String type;
        public String amiiboSeries;
        public String image;
        public Map<String, String> release;
        public String tail;
    }
    public static void main(String[] args) {
        SwingUtilities.invokeLater(AmiiboSearchApp::new);
    }
}