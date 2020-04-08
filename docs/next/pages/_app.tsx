import Head from 'next/head'
import './styles.css'



export default function ({ Component, pageProps }) {
    return (
        <>
            <Head>
                <title>Riptide</title>
                <link
                    rel="stylesheet"
                    href="https://fonts.googleapis.com/css?family=Poppins:100,200,300,400,500,600,700,800,900&display=swap"
                    as="font"
                    crossOrigin=""
                />
                <link
                    rel="stylesheet"
                    href="https://fonts.googleapis.com/css?family=IBM+Plex+Mono:100,200,300,400,500,600,700&display=swap"
                    as="font"
                    crossOrigin=""
                />

            </Head>
            <div className="font-poppins font-poppins leading-none">
                <Component {...pageProps} />
            </div>
        </>
    )
}